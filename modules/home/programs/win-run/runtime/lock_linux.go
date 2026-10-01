package runtime

import (
	"context"
	"os"
	"syscall"
)

// Lock owns an advisory file lock until Close is called.
type Lock struct {
	file *os.File
}

// AcquireLock holds a lock on an open file description, released if a process dies.
// Never unlink a lock file: replacing its inode would permit two owners.
func AcquireLock(ctx context.Context, path string) (*Lock, error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, err
	}
	result := make(chan error)
	go func() {
		err := syscall.Flock(int(file.Fd()), syscall.LOCK_EX)
		select {
		case result <- err:
		case <-ctx.Done():
			// Closing an fd from another goroutine cannot cancel a blocking
			// flock safely. Its owning goroutine releases it when it returns.
			if err == nil {
				syscall.Flock(int(file.Fd()), syscall.LOCK_UN)
			}
			file.Close()
		}
	}()
	select {
	case err := <-result:
		if err != nil {
			file.Close()
			return nil, err
		}
		if err := ctx.Err(); err != nil {
			release(file)
			return nil, err
		}
		return &Lock{file: file}, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func release(file *os.File) error {
	syscall.Flock(int(file.Fd()), syscall.LOCK_UN)
	return file.Close()
}

// Close releases the lock without replacing its inode.
func (lock *Lock) Close() error {
	return release(lock.file)
}
