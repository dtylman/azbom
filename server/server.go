package server

import (
	"context"
	"fmt"
	"time"

	"github.com/dtylman/azbom/config"
	"github.com/dtylman/azbom/sbom"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type Server struct {
	// e is the echo context
	e *echo.Echo
	// db is the sbom file
	db *sbom.File
	// dbTicker is the timer for updating the database
	dbTicker *time.Ticker
}

// NewServer creates a new server
func NewServer() *Server {
	return &Server{
		db: sbom.NewFile(),
	}
}

func (s *Server) Start(ctx context.Context) error {
	s.e = echo.New()
	s.e.Debug = true //set debug mode for now
	logconf := middleware.DefaultLoggerConfig
	logconf.Format = "${time_rfc3339_nano} ${id} ${remote_ip} ${host} ${method} ${uri} ${status} ${error} \n"

	s.e.Use(middleware.LoggerWithConfig(logconf))

	s.e.Use(middleware.StaticWithConfig(middleware.StaticConfig{
		Root:   config.Options.FrontFolder,
		Index:  "sbom.html",
		Browse: true,
		HTML5:  true,
	}))

	s.initRoutes()

	err := s.initDB(ctx)
	if err != nil {
		return fmt.Errorf("error initializing database: %v", err)
	}

	return s.e.Start(config.Options.ListenPort)
}
