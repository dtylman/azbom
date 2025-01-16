package server

import (
	"context"
	"errors"
	"fmt"
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
			err := s.updateDB(context.Background())
			if err != nil {
				log.Printf("Error updating database: %v", err)
			}
		}
	}
}

func (s *Server) initDB(ctx context.Context) error {
	// install the timer for updating the database every MaxAge hours
	s.dbTicker = time.NewTicker(time.Hour)
	go s.onUpdateDBTimer()

	// load the database
	err := s.db.Load()
	if err == nil {
		if time.Since(s.db.Created) > time.Duration(config.Options.MaxAge)*time.Hour {
			log.Printf("Database is %v hours old, updating", time.Since(s.db.Created).Hours())
			return s.updateDB(ctx)
		} else {
			return nil
		}
	}

	return s.updateDB(ctx)
}

func (s *Server) updateDB(ctx context.Context) error {
	log.Printf("Updating database")
	if config.Options.OrganizationURL == "" {
		return errors.New("organization URL is not set (use env var: ORGANIZATION_URL)")
	}
	if config.Options.Pat == "" {
		return errors.New("personal access token is not set (use env var: PAT)")
	}

	a := sbom.NewAnalyzer(config.Options.OrganizationURL, config.Options.Pat)

	err := a.Analyze(ctx)
	if err != nil {
		return fmt.Errorf("error analyzing: %v", err)
	}

	s.db = a.GetDB()

	return s.db.Save()
}
