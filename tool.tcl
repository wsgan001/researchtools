#Author: Vineet Karkera
package require Tk

proc splitFile { } {
	set fn "splitFile"
	global f

	set myFile [tk_getOpenFile]

	# Load file into a variable
	set fp [open $myFile r];
	set file_data [read $fp];
	puts $file_data;

	#count number of columns


	#find difference of two files


	#count number of rows


	#split result into separate arrays of columns



} ; 

#proc to open first file
proc openFile1 { } {
set fn "openFile1"
global f

set myFile [tk_getOpenFile]

puts stdout [format "%s:myFile=<%s>" $fn $myFile]

set fileID [open $myFile r]
set i 1
$f.text1 delete 1.0 end
while { [gets $fileID line] >= 0 } {
	puts stdout [format "line(%d)=%s" $i $line]
	$f.text1 insert end [format "%s\n" $line]
	incr i
	} ;

close $fileID

} ; 

# proc to open second file
proc openFile2 { } {
set fn "openFile2"
global f

set myFile [tk_getOpenFile]

puts stdout [format "%s:myFile=<%s>" $fn $myFile]

set fileID [open $myFile r]
set i 1
$f.text2 delete 1.0 end
while { [gets $fileID line] >= 0 } {
	puts stdout [format "line(%d)=%s" $i $line]
	$f.text2 insert end [format "%s\n" $line]
	incr i
	} ;

close $fileID
} ;

#setting up window
wm geometry  .   400x650+10+10
wm title  .   "Privacy Preserving Algorithm Analysis Tool"

#setting up the frame stuff
destroy .myArea
set f [frame .myArea -borderwidth 10 -background orange]


#widgets in the window

#first widget - name of tool
label $f.border1 -text "----------------------------------------------" -background orange
pack $f.border1 -padx 20 -pady 5
label $f.lbl1 -text "Welcome to the Privacy Preserving Analysis tool" -background orange
label $f.border2 -text "----------------------------------------------" -background orange
pack $f.lbl1 -padx 20 -pady 5
pack $f.border2 -padx 20 -pady 5

#second widget - upload file label
label $f.lbl2 -text "Step 1 : Upload Input File" -background orange -compound left 
pack $f.lbl2  -padx 20

#third widget - Browse button
button $f.browse1 -text "Browse" -background lightgrey -command {openFile1}
pack $f.browse1  -padx 20

text $f.text1 -bd 2 -bg white -height 7
pack $f.text1 -padx 20 -pady 5

#fourth widget - upload file label
label $f.lbl3 -text "Step 2 : Upload Output File" -background orange -compound left 
pack $f.lbl3  -padx 20

#fifth widget - Browse button
button $f.browse2 -text "Browse" -background lightgrey -command {openFile2}
pack $f.browse2  -padx 20

text $f.text2 -bd 2 -bg white -height 7
pack $f.text2 -padx 20 -pady 5

#sixth widget - browse button
button $f.analyze -text "Analyze Now" -background lightgrey -command {exit}
pack $f.analyze -padx 20 -pady 20

#widget - list of metrics
label $f.lbl4 -text "Efficiency  %" -background orange -compound left 
label $f.lbl5 -text "Accuracy  %" -background orange -compound left 
label $f.lbl6 -text "Privacy  %" -background orange -compound left 
label $f.lbl7 -text "Metric 3" -background orange -compound left 
label $f.lbl8 -text "Metric 4" -background orange -compound left 
label $f.lbl9 -text "Metric 5" -background orange -compound left 
label $f.lbl10 -text "Metric 6" -background orange -compound left
 
pack $f.lbl4 $f.lbl5 $f.lbl6 $f.lbl7 $f.lbl8 $f.lbl9 $f.lbl10  -padx 20

pack $f -side top -expand true -fill both 

# lines within the text area
$f.text1 insert end "Please upload a csv file from the menu\n" tag0
$f.text1 insert end "Or paste the contents of the sample input file here.." tag1

$f.text2 insert end "Please upload a csv file from the menu\n" tag0
$f.text2 insert end "Or paste the contents of the sample output file here.." tag1

#creates a menubar
menu .menubar
. config -menu .menubar

#creates a pull down menu with a label 
set File [menu .menubar.mFile]
.menubar add cascade -label File  -menu  .menubar.mFile

#creates a new pull down for quit
set Quit [menu .menubar.quit]
.menubar add cascade -label {Quit} -menu  .menubar.quit

#options for the file drop down
$File add command -label {Open File 1 (Sample input file)} -command openFile1
$File add command -label {Open File 2 (Sample output file)} -command openFile2

#options for the second drop down
$Quit add command -label {Yes, I want to leave!} -command exit
$Quit add command -label {No, I'll stay.}
