param 
( 
    [parameter()][string] $FolderPath = "D:\a\1\s\",
    [parameter()][string[]] $FileExtension = ".dll"
) 
 
#Create Table object
$table = New-Object system.Data.DataTable “FileList”
 
#Define Columns
$col1 = New-Object system.Data.DataColumn FileName,([string])
$col2 = New-Object system.Data.DataColumn SignStatus,([string])
$col3 = New-Object system.Data.DataColumn FullName,([string])
$col4 = New-Object system.Data.DataColumn DirectoryName,([string])
 
#Add the Columns
$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)
$table.columns.add($col4)
 
#Passing the Foderpath
 

    $Dir = get-childitem $FolderPath -recurse 
    $List = $Dir | where {$_.extension -eq $FileExtension} 
    #checking for signed and unsigned files
    $i=0
    foreach ($item in $List)
       {
          $cert= $(get-AuthenticodeSignature $item.FullName).SignerCertificate.Subject
 
               #Create a row
                $row = $table.NewRow()
                #Enter data in the row
                $row.FileName = $item.Name
                $row.FullName = $item.FullName
                $row.SignStatus = $cert
                $row.DirectoryName = $item.DirectoryName
                #Add the row to the table
                 $table.Rows.Add($row)     
         }
          
        foreach ($item in $List)
     {
        ## check the cert/file signature
        $cert= $(get-AuthenticodeSignature $item.FullName).SignerCertificate.Subject
 
        ## if the cert/file is signed, move it unsigned  to new location
        if ($cert.Length -eq 0)
        {
            for ($i = 0; $i -lt $table.Rows.Count; $i++)
            {
                if ($item.Name -eq $table.Rows[$i]["FileName"])
                {
                    Move-Item -Path $table.Rows[$i]["FullName"].ToString() -Destination "D:\a\1\s\unsigned"
                }
            }
        }
 
     }
  
 
        $SignedTable = $table.Clone()
        $UnSignedTable = $table.Clone()
 
       for ($i = 0; $i -lt $table.Rows.Count; $i++)
       { 
           if ($table.Rows[$i]["SignStatus"].Count -eq 1)
           {
               $UnSignedTableRow = $UnSignedTable.NewRow()
               
               $UnSignedTableRow.DirectoryName = $table.Rows[$i]["DirectoryName"]
               $UnSignedTableRow.FileName = $table.Rows[$i]["FileName"]
               $UnSignedTableRow.FullName = $table.Rows[$i]["FullName"]
               $UnSignedTableRow.SignStatus = $table.Rows[$i]["SignStatus"]
               
               $UnSignedTable.Rows.Add($UnSignedTableRow)
           }
           else
           {
               $SignedTableRow = $SignedTable.NewRow()
               
               $SignedTableRow.DirectoryName = $table.Rows[$i]["DirectoryName"]
               $SignedTableRow.FileName = $table.Rows[$i]["FileName"]
               $SignedTableRow.FullName = $table.Rows[$i]["FullName"]
               $SignedTableRow.SignStatus = $table.Rows[$i]["SignStatus"]
               
               $SignedTable.Rows.Add($SignedTableRow)
           }
       }
 
    $table | format-table -AutoSize  | format-table Name 
    $UnSignedTable | format-table -AutoSize  | format-table Name 
    $SignedTable | format-table -AutoSize  | format-table Name 
 
    $tabCsv = $table | export-csv $($FolderPath + "\files1.csv") -noType 
    $UnSignedCSV = $UnSignedTable | export-csv -Append $($FolderPath + "\UnSigned.csv") -noType 
    $SignedCSV = $SignedTable | export-csv -Append $($FolderPath + "\Signed.csv") -noType 
 
