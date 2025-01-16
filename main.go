package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/dtylman/azbom/server"
	"github.com/labstack/gommon/log"
)

func main() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		os.Exit(0)
	}()

	s := server.NewServer()

	ctx := context.Background()
	err := s.Start(ctx)
	if err != nil {
		log.Errorf("Error starting server: %v", err)
	}

}
