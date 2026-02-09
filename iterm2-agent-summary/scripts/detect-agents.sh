#!/bin/bash
# Reads iTerm2 tabs and outputs tab content with markers

osascript << 'EOF'
tell application "iTerm2"
  set output to ""
  set winNum to 0
  repeat with w in windows
    set winNum to winNum + 1
    set tabNum to 0
    repeat with t in tabs of w
      set tabNum to tabNum + 1
      try
        set sess to current session of t
        set tabContent to contents of sess
        
        -- Get first 50 lines (original prompt) and last 50 lines (current status)
        set lineList to paragraphs of tabContent
        set lineCount to count of lineList
        
        -- First 50 lines
        set firstLines to ""
        if lineCount > 50 then
          repeat with i from 1 to 50
            set firstLines to firstLines & (item i of lineList) & linefeed
          end repeat
        else
          repeat with i from 1 to lineCount
            set firstLines to firstLines & (item i of lineList) & linefeed
          end repeat
        end if
        
        -- Last 50 lines (if different from first)
        set lastLines to ""
        if lineCount > 100 then
          repeat with i from (lineCount - 50) to lineCount
            set lastLines to lastLines & (item i of lineList) & linefeed
          end repeat
        else if lineCount > 50 then
          repeat with i from 51 to lineCount
            set lastLines to lastLines & (item i of lineList) & linefeed
          end repeat
        end if
        
        set output to output & "###WIN" & winNum & "TAB" & tabNum & "###" & linefeed & firstLines & "---RECENT---" & linefeed & lastLines
      end try
    end repeat
  end repeat
  return output
end tell
EOF
