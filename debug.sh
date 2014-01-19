#! /bin/zsh -x

local -a tmux untmux
tmux=("./tmux" -L debug)
untmux=(env -u TMUX -u TMUX_PANE)

gdb()
{
  cgdb "$@"
}

gdbserver()
{
  xterm -hold -e $untmux gdbserver localhost:4242 $tmux &
  xterm_pid=$!

  while ! pgrep -P $xterm_pid gdbserver
  do
    sleep 1
  done

  sleep 1

  exec gdb -ex 'symbol-file ./tmux' -ex 'target remote localhost:4242'
}

gdbattach()
{
  xterm -e $untmux $tmux &
  xterm_pid=$!

  while ! tmux_pid=`pgrep -P $xterm_pid tmux`
  do
    sleep 1
  done

  exec gdb ./tmux $tmux_pid
  exit $?
}

debuglog()
{
  rm -f tmux-{client,server}-[0-9]*.log

  xterm -e $untmux $tmux -v &
  xterm_pid=$!

  while ! tmux_pid=`pgrep -P $xterm_pid tmux`
  do
    sleep 1
  done

  tail -v -f --pid=$tmux_pid tmux-client-$tmux_pid.log tmux-server-*.log
}

xtermlog()
{
  rm -f xterm.log Trace-{child,parent}.out

  xterm-trace -l -lf xterm.log -e $untmux $tmux &
  xterm_pid=$!

  tail -v -F --pid=$xterm_pid Trace-{child,parent}.out
}

tmuxterm()
{
  xterm -e $untmux $tmux "$@"
}

$untmux $tmux kill-server
$untmux $tmux start-server

tmuxterm "$@"

