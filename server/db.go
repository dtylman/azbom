package server

import (
	"context"
	"log"
	"time"

	"github.com/dtylman/azbom/config"
	"github.com/dtylman/azbom/sbom"
)

func (s *Server) onUpdateDBTimer() {
	if s.dbTicker == nil {
		return
	}

	for range s.dbTicker.C {
		age := time.Since(s.db.Created)
		log.Printf("Database is %v hours old,", age.Hours())
		if age > time.Duration(config.Options.MaxAge)*time.Hour {
			log.Printf("Database is old but no automatic refresh configured. Use the frontend refresh feature.")
		}
	}
}

func (s *Server) initDB(ctx context.Context) error {
	// install the timer for monitoring database age
	s.dbTicker = time.NewTicker(time.Hour)

	go s.onUpdateDBTimer()

	// Try to load existing database, create empty one if it doesn't exist
	err := s.db.Load()
	if err != nil {
		log.Printf("Could not load existing database: %v. Starting with empty database.", err)
		// Initialize with empty database
		s.db = sbom.NewFile()
	}

	return nil
}
