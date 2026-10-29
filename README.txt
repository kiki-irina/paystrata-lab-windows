PAYSTRATA LAB (WINDOWS)
=======================
Session 1: "The Bottleneck That Only Appears at Peak Hours".
The same server, the same data, the same traffic. Only the SQL (or the isolation level) changes.

  Test 1: INSERT ... ON DUPLICATE KEY UPDATE (IODKU) versus UPDATE first, 1 -> 50 sessions
  Test 2: IODKU under REPEATABLE READ versus READ COMMITTED, 1 -> 50 sessions

This is the Windows version. The macOS / Linux version uses .sh scripts and Colima.


WHAT YOU NEED (ONCE)
--------------------
1. Windows 10 or 11 with Docker Desktop (WSL 2 backend, the default).
   https://www.docker.com/products/docker-desktop/
   Give it at least 4 CPUs and 8 GB RAM: Settings > Resources (with WSL 2 this is in
   %UserProfile%\.wslconfig).
2. Git for Windows:  https://git-scm.com/download/win
3. Python 3 (only for the charts):  https://www.python.org/downloads/
   Tick "Add python.exe to PATH" in the installer.
4. Port 3307 must be free.

Use PowerShell (not cmd). Start Docker Desktop and wait until it says "Engine running".


GET THE LAB
-----------
    git clone https://github.com/kiki-irina/paystrata-lab-windows.git
    cd paystrata-lab-windows


ONE-TIME SETUP FOR THE CHARTS
-----------------------------
    py -m venv .venv
    .\.venv\Scripts\python.exe -m pip install matplotlib

If you skip this, the tests still run. Only the PNG charts are not drawn.


IF POWERSHELL REFUSES TO RUN THE SCRIPTS
----------------------------------------
Error: "running scripts is disabled on this system". Allow scripts for this window only:

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Run it again in every new PowerShell window. Nothing is changed permanently.


RUN THE TESTS
-------------
Window 2 (optional, live view of locks and deadlocks):

    .\monitor.ps1

Window 1:

    .\test1.ps1
    .\test2.ps1

Each test rebuilds the whole environment first (containers, data, table). Rows appear as
each level (1, 5, 10, 25, 50 sessions) finishes. Test 1 takes about 4 minutes of load, test 2
about the same.

Options:

    .\test1.ps1 -Destroy        remove the containers and data at the end
    .\run_all.ps1               test 1, test 2, then destroy everything

Results:

    results\test1.csv, results\test1.png
    results\test2_rr.csv, results\test2_rc.csv, results\test2.png


MONITOR OPTIONS
---------------
    .\monitor.ps1                 refresh every 6 seconds
    .\monitor.ps1 -Interval 2     every 2 seconds
    .\monitor.ps1 -Once           one snapshot and exit
    .\monitor.ps1 -Keep           do not clear the screen
    Ctrl+C                        stop

Four panels: sessions and transactions, who blocks whom, locks grouped by index and mode,
deadlock and lock-wait counters.


RUN THE PIECES BY HAND
----------------------
Environment only (no test):

    .\setup_env.ps1

One level, one variant (for example the IODKU at 25 sessions):

    docker compose run --rm -T loadgen run --variant iodku --threads 25

Full ramp, one variant, your own output name:

    docker compose run --rm -T loadgen ramp --variants iodku --out my_run

READ COMMITTED:

    docker compose run --rm -T loadgen ramp --variants iodku --isolation "READ COMMITTED" --out my_rc

Open a MySQL prompt in the database:

    docker exec -it paystrata-db mysql -uroot -ppaystrata paystrata

Destroy everything:

    docker compose down -v


TROUBLESHOOTING
---------------
"port is already allocated" on 3307
    Another container or program uses it. Find it:
        docker ps --format "{{.Names}}  {{.Ports}}"
        netstat -ano | findstr :3307
    Remove the old container:  docker rm -f <name>

"Docker is not running"
    Start Docker Desktop and wait for "Engine running".

"the input device is not a TTY"
    Add -T after "run" (all the scripts already do).

The chart is not drawn
    Do the one-time venv setup above.

Files edited on Windows break in the container (strange ^M errors)
    The repo forces LF line endings (.gitattributes). If you copied files by hand, clone again.

The database never becomes healthy
    docker compose logs db
    Usually not enough memory given to Docker Desktop.


LAB DESIGN (SHORT)
------------------
One "payment" = one transaction that updates 3 merchants in random order, with a 2 ms pause
between statements. 80% of the traffic goes to the first 1,000 merchants and 5% of the keys do
not exist yet. On a deadlock (error 1213) the payment is rolled back and retried up to 3 more
times. Before each level the table is emptied and reloaded (19,000 merchants), so every
level starts from the same data. Each level lasts 20 seconds.

Numbers from a laptop: compare the ratios, not the absolute values.
