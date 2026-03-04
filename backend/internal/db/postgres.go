package db

// PGConn is a minimal PostgreSQL client that speaks the v3 wire protocol
// using only the Go standard library (no external driver required).
// It supports trust and MD5 password authentication, and text-format
// simple queries (no prepared statements / extended query protocol).

import (
	"crypto/md5"
	"encoding/binary"
	"fmt"
	"io"
	"net"
)

// PGConfig holds connection parameters.
type PGConfig struct {
	Host     string
	Port     string
	DBName   string
	User     string
	Password string
}

// PGConn wraps a raw TCP connection to a PostgreSQL server.
type PGConn struct {
	c net.Conn
}

// PGRows holds the result set of a query.
type PGRows struct {
	Columns []string
	rows    [][]string // text values; NULL columns are empty string
	pos     int
}

// Next advances to the next row. Returns false when all rows have been read.
func (r *PGRows) Next() bool {
	if r.pos < len(r.rows) {
		r.pos++
		return true
	}
	return false
}

// Values returns the current row's column values (one string per column).
func (r *PGRows) Values() []string {
	return r.rows[r.pos-1]
}

// ConnectPostgres dials the PostgreSQL server and authenticates.
func ConnectPostgres(cfg PGConfig) (*PGConn, error) {
	addr := net.JoinHostPort(cfg.Host, cfg.Port)
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return nil, fmt.Errorf("postgres dial %s: %w", addr, err)
	}
	pg := &PGConn{c: conn}
	if err := pg.startup(cfg.User, cfg.DBName, cfg.Password); err != nil {
		_ = conn.Close()
		return nil, err
	}
	return pg, nil
}

// Query executes a simple SQL statement and returns all result rows.
func (pg *PGConn) Query(sql string) (*PGRows, error) {
	if err := pg.writeFrontendMsg('Q', append([]byte(sql), 0)); err != nil {
		return nil, err
	}
	res := &PGRows{}
	for {
		msgType, body, err := pg.readMsg()
		if err != nil {
			return nil, err
		}
		switch msgType {
		case 'T': // RowDescription
			res.Columns = pgParseRowDesc(body)
		case 'D': // DataRow
			res.rows = append(res.rows, pgParseDataRow(body))
		case 'C', 'I': // CommandComplete, EmptyQueryResponse
			// continue to ReadyForQuery
		case 'Z': // ReadyForQuery — done
			return res, nil
		case 'E': // ErrorResponse
			return nil, fmt.Errorf("postgres: %s", pgErrMsg(body))
		}
	}
}

// Close sends a Terminate message and closes the TCP connection.
func (pg *PGConn) Close() {
	_ = pg.writeFrontendMsg('X', nil)
	_ = pg.c.Close()
}

// -------------------------------------------------------------------------
// internal helpers

// startup sends the startup packet and negotiates authentication.
func (pg *PGConn) startup(user, dbname, password string) error {
	// Startup message: int32(total_len) int32(protocol) key=value... NUL
	var buf []byte
	buf = append(buf, 0, 0, 0, 0)    // placeholder for message length
	buf = append(buf, 0, 3, 0, 0)    // protocol version 3.0 (196608)
	buf = append(buf, "user"...)
	buf = append(buf, 0)
	buf = append(buf, user...)
	buf = append(buf, 0)
	buf = append(buf, "database"...)
	buf = append(buf, 0)
	buf = append(buf, dbname...)
	buf = append(buf, 0)
	buf = append(buf, 0) // terminating NUL
	binary.BigEndian.PutUint32(buf[:4], uint32(len(buf)))
	if _, err := pg.c.Write(buf); err != nil {
		return err
	}

	// Process authentication messages until ReadyForQuery.
	for {
		msgType, body, err := pg.readMsg()
		if err != nil {
			return err
		}
		switch msgType {
		case 'R': // AuthenticationRequest
			if len(body) < 4 {
				return fmt.Errorf("postgres: malformed auth message")
			}
			authType := int32(binary.BigEndian.Uint32(body[:4]))
			switch authType {
			case 0: // AuthenticationOk — wait for ReadyForQuery
			case 5: // AuthenticationMD5Password
				if len(body) < 8 {
					return fmt.Errorf("postgres: short MD5 auth body")
				}
				salt := body[4:8]
				h1 := md5.Sum([]byte(password + user))
				h1Hex := fmt.Sprintf("%x", h1)
				h2Input := append([]byte(h1Hex), salt...)
				h2 := md5.Sum(h2Input)
				resp := append([]byte("md5"+fmt.Sprintf("%x", h2)), 0)
				if err := pg.writeFrontendMsg('p', resp); err != nil {
					return err
				}
			default:
				return fmt.Errorf("postgres: unsupported auth type %d", authType)
			}
		case 'Z': // ReadyForQuery
			return nil
		case 'E': // ErrorResponse
			return fmt.Errorf("postgres auth error: %s", pgErrMsg(body))
		// 'S' ParameterStatus, 'K' BackendKeyData — ignore
		}
	}
}

// readMsg reads one complete backend message.
// Backend format: type(1) + length(4, includes itself) + body(length-4).
func (pg *PGConn) readMsg() (byte, []byte, error) {
	hdr := make([]byte, 5)
	if _, err := io.ReadFull(pg.c, hdr); err != nil {
		return 0, nil, err
	}
	msgType := hdr[0]
	bodyLen := int(binary.BigEndian.Uint32(hdr[1:])) - 4
	if bodyLen <= 0 {
		return msgType, nil, nil
	}
	body := make([]byte, bodyLen)
	if _, err := io.ReadFull(pg.c, body); err != nil {
		return 0, nil, err
	}
	return msgType, body, nil
}

// writeFrontendMsg writes a tagged frontend message.
// Frontend format: type(1) + length(4, includes itself) + payload.
func (pg *PGConn) writeFrontendMsg(msgType byte, payload []byte) error {
	buf := make([]byte, 5+len(payload))
	buf[0] = msgType
	binary.BigEndian.PutUint32(buf[1:], uint32(4+len(payload)))
	copy(buf[5:], payload)
	_, err := pg.c.Write(buf)
	return err
}

// pgParseRowDesc extracts column names from a RowDescription message.
// Each field: name(cstr) + tableOID(4) + colIdx(2) + typeOID(4) + typeSize(2) + typeMod(4) + fmt(2) = 18 fixed bytes after name.
func pgParseRowDesc(body []byte) []string {
	if len(body) < 2 {
		return nil
	}
	n := int(binary.BigEndian.Uint16(body[:2]))
	cols := make([]string, 0, n)
	pos := 2
	for i := 0; i < n && pos < len(body); i++ {
		end := pos
		for end < len(body) && body[end] != 0 {
			end++
		}
		cols = append(cols, string(body[pos:end]))
		pos = end + 1 + 18 // skip null terminator + 18 bytes of field metadata
	}
	return cols
}

// pgParseDataRow parses a DataRow message into a slice of string values.
// NULL columns are represented as empty strings.
func pgParseDataRow(body []byte) []string {
	if len(body) < 2 {
		return nil
	}
	n := int(binary.BigEndian.Uint16(body[:2]))
	vals := make([]string, n)
	pos := 2
	for i := 0; i < n && pos+4 <= len(body); i++ {
		l := int(int32(binary.BigEndian.Uint32(body[pos:])))
		pos += 4
		if l < 0 {
			vals[i] = "" // NULL
		} else {
			vals[i] = string(body[pos : pos+l])
			pos += l
		}
	}
	return vals
}

// pgErrMsg extracts the human-readable message field ('M') from an ErrorResponse body.
func pgErrMsg(body []byte) string {
	i := 0
	for i < len(body) {
		field := body[i]
		i++
		start := i
		for i < len(body) && body[i] != 0 {
			i++
		}
		if field == 'M' {
			return string(body[start:i])
		}
		i++ // skip NUL
	}
	return "(unknown error)"
}
