Attribute VB_Name = "mdlMain"
Sub main()
Dim out As String
    Dim num As Long
    Dim incSize As Long
    Dim isStar As Boolean
    
    Open App.Path & "\eliza.dat" For Input As #1
    Open App.Path & "\replies.inc" For Output As #2
        Print #2, "; REPLIES.INC GENERATED " & Time
        Do Until EOF(1)
            Input #1, x
            If Right(x, 1) = "*" Then
                x = Left(x, Len(x) - 1)
                isStar = True
            Else
                isStar = False
            End If
            If x = "!" Then
                Print #2, Chr(9) & ".db -1 ;END"
                Print #2, "Reply_" & num & ":"
                num = num + 1
            ElseIf x = "." Then
                If num <> 0 Then Print #2, Chr(9) & ".db -1 ;END"
                Print #2, "Query_" & num & ":"
            Else
            
            
                For i = 1 To Len(x) Step 16
                    Print #2, Chr(9) & ".db """ & Mid(x, i, 16) & """"
                Next i
                
                If i < Len(x) Then
                    Print #2, Chr(9) & ".db """ & Mid(x, i, Len(x) - i) & """"
                End If
                
                Print #2, Chr(9) & ".db 0"
                If isStar Then Print #2, Chr(9) & ".db ""*"",0"
                incSize = incSize + Len(x) + 1
                
            End If
        Loop
        
        Print #2, Chr(9) & ".db -1 ;END"
        incSize = incSize + 1
        
        Print #2, "ReplyIndex:"
        For i = 0 To num - 1
            Print #2, Chr(9) & ".dw Query_" & i & ", Reply_" & i & ", Reply_" & i
            incSize = incSize + 6
        Next i
        
        Print #2, Chr(9) & ".dw 0,0"
        incSize = incSize + 2
         
        Print #2, "; TOTAL SIZE: " & incSize & " bytes"
        
    Close #2
    Close #1
    Beep
    End
    End Sub
