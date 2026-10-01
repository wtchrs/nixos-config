package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

// Nix supplies the runtime paths without coupling the application packages to
// this executable or to its build system.
var defaultProton, defaultUMU string

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	status, err := run(ctx, os.Args[1:], defaultProton, defaultUMU)
	stop()
	if err != nil {
		fmt.Fprintln(os.Stderr, "win-run:", err)
		if status == 0 {
			status = 2
		}
	}
	os.Exit(status)
}
