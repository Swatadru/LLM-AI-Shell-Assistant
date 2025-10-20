#!/bin/bash
# ===========================================================
#  Project: LLM-Backed Shell Command Assistant (Offline)
#  Author : Swatadru Paul
#  Description:
#     A shell-based assistant that interprets natural language
#     requests and suggests equivalent Linux commands.
#     Demonstrates shell parsing, process management,
#     and I/O redirection.
# ===========================================================

# ---------- Colors ----------
BOLD=$(tput bold)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)

# ---------- Setup ----------
LOGDIR="logs"
LOGFILE="$LOGDIR/session.log"
OUTPUTFILE="$LOGDIR/output.txt"
mkdir -p "$LOGDIR"

# ---------- Create Sample Demo Files ----------
mkdir -p app server
if [[ ! -f app/debug.log ]]; then
    echo "Error found in module" > app/debug.log
    echo "Everything fine" >> app/debug.log
fi
if [[ ! -f server/system.log ]]; then
    echo "Critical error initializing" > server/system.log
    echo "Startup complete" >> server/system.log
fi

clear
echo "=========================================================="
echo "${CYAN}${BOLD}🧠  LLM-Backed Shell Command Assistant (Offline)${RESET}"
echo "=========================================================="
echo

# ========== Main Loop ==========
while true; do
    echo -n "${YELLOW}Enter your request (or type 'exit' to quit): ${RESET}"
    read query

    # Exit condition
    if [[ "$query" == "exit" ]]; then
        echo
        echo "${GREEN}👋 Goodbye!${RESET}"
        echo
        break
    fi

    # Convert query to lowercase
    lower=$(echo "$query" | tr 'A-Z' 'a-z')
    cmd=""

    # ---------------- Rule-based interpretation ----------------

    # --- FIND FILES ---
    if [[ "$lower" == *"find"* && "$lower" == *".log"* ]]; then
        cmd="find . -type f -name \"*.log\""
        if [[ "$lower" == *"2 day"* || "$lower" == *"last 2 day"* ]]; then
            cmd="$cmd -mtime -2"
        elif [[ "$lower" == *"1 day"* || "$lower" == *"yesterday"* ]]; then
            cmd="$cmd -mtime -1"
        fi
    fi

    # --- SEARCH CONTENT ---
    if [[ "$lower" == *"contain"* || "$lower" == *"error"* || "$lower" == *"search"* ]]; then
        keyword=$(echo "$query" | grep -oE '"[^"]+"' | head -n1 | tr -d '"')
        if [[ -n "$keyword" ]]; then
            if [[ -n "$cmd" ]]; then
                # Add line numbers and format output without date
                cmd="$cmd -not -path './logs/*' -exec grep -Hn \"$keyword\" {} \\; | awk -F: '{print \$1\":\"\$2\":\"substr(\$0, index(\$0,\$3))}'"
            else
                cmd="grep -rn \"$keyword\" . | awk -F: '{print \$1\":\"\$2\":\"substr(\$0, index(\$0,\$3))}'"
            fi
        fi
    fi

    # --- COUNT FILES ---
    if [[ "$lower" == *"count"* && "$lower" == *"file"* ]]; then
        ext=$(echo "$lower" | grep -oE "\.[a-z0-9]+" | head -n1)
        if [[ -n "$ext" ]]; then
            cmd="find . -type f -name \"*${ext}\" | wc -l"
        else
            cmd="find . -type f | wc -l"
        fi
    fi

    # --- DISK USAGE ---
    if [[ "$lower" == *"disk usage"* || "$lower" == *"space"* ]]; then
        cmd="du -sh * | sort -h"
    fi

    # --- LIST LARGE FILES ---
    if [[ "$lower" == *"large"* || "$lower" == *"biggest"* ]]; then
        cmd="ls -lhS | head"
    fi

    # --- Fallback ---
    if [[ -z "$cmd" ]]; then
        echo
        echo "${RED}🤔 Sorry, I couldn't understand that request.${RESET}"
        echo "${CYAN}Try examples like:${RESET}"
        echo "  🔹 Find all .log files containing \"error\""
        echo "  🔹 Count all .txt files"
        echo "  🔹 Show disk usage"
        echo
        continue
    fi

    # ---------------- Display Suggested Command ----------------
    echo
    echo "${BLUE}${BOLD}💡 Suggested Command:${RESET}"
    echo "${CYAN}$cmd${RESET}"
    echo

    # Log query and command
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $query | $cmd" >> "$LOGFILE"

    # ---------------- Execution Option ----------------
    echo -n "${YELLOW}Do you want to execute it? (y/n): ${RESET}"
    read ans
    echo

    if [[ "$ans" == "y" ]]; then
        echo "=========================================================="
        echo "${GREEN}${BOLD}🔹 Running Command...${RESET}"
        echo "=========================================================="
        echo

        # Execute command, show output, and save it
        eval "$cmd" 2>&1 | tee "$OUTPUTFILE"

        echo
        echo "=========================================================="
        echo "${GREEN}✅ Execution Complete${RESET}"
        echo "📄 Output saved to: ${CYAN}$OUTPUTFILE${RESET}"
        echo "🕒 Logged in: ${CYAN}$LOGFILE${RESET}"
        echo "=========================================================="
        echo
    else
        echo "${YELLOW}Skipped execution.${RESET}"
        echo
    fi
done
