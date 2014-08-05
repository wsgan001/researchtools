#!/usr/bin/env tclsh
#Author: Vineet Karkera
package require Tk
package require BWidget

# default values
# contains column names
set colNames ""

# empty sensitive array
set sensitiveArray [list]

# default values of metrics
set missesCost 0.0
set informationLoss 0.0
set hidingFailure 0.0

# initialize number of elements
set sensitiveElementDifference 0
set nonSensitiveElementDifference 0
set numberOfSensitiveElements 0
set numberOfNonSensitiveElements 0

# procedure to create a list containing the penalty values of each attribute
proc setPenaltyArray {} {
	global colNames mySensitiveArray
	
	# a dictionary containing level of sensitivity of each column, as given by the user
	set mySensitiveArray [dict create "column_name" "sensitivity"]
	
	# loop to create dynamic variables
	for {set i 0} {$i < [expr [llength $colNames]]} {incr i} {
		global checkbox$i
		set val [set checkbox$i]
		dict lappend mySensitiveArray $i $val
	}
	
	# call procedure to obtain the maximum penalty of the Quasi Identifiers
	getMaxQIPenalty;
}

# procedure to create a list containing the Quasi Identifiers
proc setQIArray {} {
	global colNames myQIArray maxPenalty

	# loop to create dynamic variables
	for {set i 0} {$i < [expr [llength $colNames]]} {incr i} {
		global qiCheckbox$i
		# a dictionary containing the QI, as given by the user
		set val [set qiCheckbox$i]	
		dict lappend myQIArray $i $val
	}
}

# procedure to obtain the maximum penalty value of the quasi identifiers
proc getMaxQIPenalty {} {
	global colNames myQIArray maxPenalty myScaleList

	# loop to fetch the list of QI attributes
	for {set i 0} {$i < [expr [llength $colNames]]} {incr i} {
		set val [dict get $myQIArray $i]	
		if {$val == 1} {
			global checkbox$i
			set val [expr [set checkbox$i] * 1.0]
			lappend myScaleList $val
		}
	}
	set myScaleList [lsort -real $myScaleList]
	set maxPenalty [lindex $myScaleList end]
}

# calculates PRIVACY (hiding failure) as defined by Oliveira in his paper, discussed further in the report submitted
proc getHidingFailure {} {  
	# find the number of sensitive elements that have been revealed
	global hidingFailure mySensitiveArray myQIArray numCols
	
	set count 0
	set sensitiveCounter 0
	for {set i 0} {$i < $numCols} {incr i} {
		# setting up dynamic global variables
		global col$i coln$i
		# check if the column is sensitive only then
		set value [dict get $mySensitiveArray $i]
		if {$value > 0} {
			incr sensitiveCounter
			set originalColumn [set col$i]
			set sanitizedColumn [set coln$i]
			foreach a $originalColumn b $sanitizedColumn {
				if { $a == $b } {
					incr count
				} 
			}
		}
	}	
	if {$sensitiveCounter > 0} {
		set hidingFailure [expr (($count * 100.00 )/ ([llength $col0] * $sensitiveCounter))]
	}
};

# calculates UTILITY (misses cost) as defined by Oliveira in his paper, discussed further in the report submitted
proc getMissesCost {} {
	# misses cost measures the percentage of non-restrictive patterns that are hidden after sanitization  
	global missesCost mySensitiveArray myQIArray numCols
	
	set count 0
	set nonSensitiveCounter 0
	
	for {set i 0} {$i < $numCols} {incr i} {
		# setting up dynamic global variables
		global col$i coln$i
		# check if the column is non-sensitive only then
		set value [dict get $mySensitiveArray $i]
		if {$value == 0} {
			incr nonSensitiveCounter
			set originalColumn [set col$i]
			set sanitizedColumn [set coln$i]
			foreach a $originalColumn b $sanitizedColumn {
				if { $a != $b } {
					incr count
				} 
			}
		}
	}
	if {$nonSensitiveCounter > 0} {
		set missesCost [expr (($count * 100.00 )/ ([llength $col0] * $nonSensitiveCounter))]
	}
};

# calculates ACCURACY OR DATA QUALLITY(information loss) as defined by Oliveira in his paper, discussed further in the report submitted
proc getInformationLoss {} {  
	global informationLoss col1 coln1 mySensitiveArray
	set count 0
	foreach a $col1 b $coln1 {
		if { $a != $b } {
			incr count
		} 
	}
	set informationLoss [expr (($count * 100.00 )/ [llength $col1])]
};

proc analyze {} {  
	global col1 coln1 analyzeFrame welcomeFrame missesCost hidingFailure cpuUtil checkboxHidingFailure checkboxMissesCost
	set analyzeFrame ".analyzeFrame";
	set resultsFrame ".resultsFrame";
	
	#set the start of the stopwatch
	set TIME_start [clock clicks -microseconds]
	
	# sets the QI groups given by user into a global array myQIArray
	setQIArray;
	
	# sets the values given by user into a global array mySensitiveArray
	setPenaltyArray;
	
	# computes misses cost only if explicitly selected by user, or if no metric is selected by the user
	if {($checkboxMissesCost == 1) || ($checkboxHidingFailure == 0 && $checkboxMissesCost == 0)} {
		getMissesCost;
	}
	
	# computes information loss
	#getInformationLoss;
	
	# computes hiding Failure only if explicitly selected by user, or if no metric is selected by the user
	if {($checkboxHidingFailure == 1) || ($checkboxHidingFailure == 0 && $checkboxMissesCost == 0)} {
		getHidingFailure;
	}
	
	# compares each element of the two lists passed
	#checkEachElement $col1 $coln1;
	
	#call proc to calculate CPU time
	set cpuUtil [expr [clock clicks -microseconds] - $TIME_start]
	
	#calculates time taken in the function on an average
	#puts [time {setPenaltyArray} 100]
	#puts [time {getMissesCost} 100]
	#puts [time {getHidingFailure} 100]

	if {[winfo exists $analyzeFrame]} { destroy $analyzeFrame };
	frame $analyzeFrame -borderwidth 10 -background orange;
	
	# pack the welcome frame
	pack $welcomeFrame -side top -expand true -fill both
	
	if {[winfo exists $resultsFrame]} { destroy $resultsFrame };
	frame $resultsFrame -borderwidth 10 -background orange;
	
	# widgets in the window
	label $resultsFrame.lbl10 -text "Analysis and Results" -background orange -compound left -font {Helvetica 14} 
	label $resultsFrame.lbl11 -text "Hiding Failure (HF) is the percentage of sensitive information that can still be effectively discovered after sanitizing the data" -background orange -compound left -font {Times 10}
	label $resultsFrame.lbl12 -text "Misses cost (MC) measures the percentage of non-sensitive information that is hidden after the sanitization process." -background orange -compound left -font {Times 10}
	label $resultsFrame.lbl13 -text "PRIVACY (hiding failure) and UTILITY (misses cost) of the sanitized file is calculated." -background orange -compound left -font {Times 10}
	pack $resultsFrame.lbl10 $resultsFrame.lbl13 $resultsFrame.lbl11 $resultsFrame.lbl12  -expand true -fill both -padx 10 -pady 10 -side top
	
	# widget - list of metrics
	label $analyzeFrame.lbl7 -text "Hiding Failure - [format "%.2f" $hidingFailure] %" -background orange -compound left 
	label $analyzeFrame.lbl8 -text "Misses Cost - [format "%.2f" $missesCost] %" -background orange -compound left  
	label $analyzeFrame.lbl9 -text "Time Taken - [format "%.2f" $cpuUtil] microseconds" -background orange -compound left  
	#label $analyzeFrame.lbl10 -text "CPU Utility - [format "%.2f" $cpuUtil] microseconds" -background orange -compound left  
	pack $analyzeFrame.lbl7 $analyzeFrame.lbl8 $analyzeFrame.lbl9 -padx 20 -side left -expand true -fill both
 
	# destroy previous frames and packs the new frame
	global sw
	if {[winfo exists $sw]} { destroy $sw};
	if {[winfo exists .sensitivityLabelFrame]} { destroy .sensitivityLabelFrame };
	if {[winfo exists .sensitivityFrame]} { destroy .sensitivityFrame };
	if {[winfo exists .buttonFrame]} { destroy .buttonFrame };
	pack $resultsFrame -expand true -fill both -side top
	pack $analyzeFrame -side left -expand true -fill both
	
	# call proc to draw bar chart with calculated values
	createBarChart;
};

# proc to get the first line of the file
proc getFirstLineFromFile {filename} {
	set f [open $filename r]
    set line [gets $f]
    close $f
    return $line
};

# proc to get arithmetic sum of elements in a list
proc ladd L {expr [join $L +]+0}

# proc to split the first file data into columns
proc splitIntoColumns {filename} {
	global numCols delimiter delimiterFrame
	set f [open $filename r]	
	# the first line containing header names is skipped
	set line [gets $f]
	set file_data [read $f]
	close $f
	set data [split $file_data "\n"]
    foreach {line} $data {
		set csvdata [split $line "$delimiter"]
		set i 0
		foreach {element} $csvdata {
			global col$i
			lappend col$i $element
			incr i			
		}
	}
};

# proc to split the second file data into columns
proc splitIntoColns {filename} {
	global numCols delimiter
	
	set f [open $filename r]	
	# the first line containing header names is skipped
	set line [gets $f]
	set file_data [read $f]
	close $f
	set data [split $file_data "\n"]
    foreach {line} $data {
		set csvdata [split $line "$delimiter"]
		set i 0
		foreach {element} $csvdata {
			global coln$i
			lappend coln$i $element
			incr i			
		}
	}
};
 
# proc to open first file
proc openFile1 {} {
	set fn "openFile1"
	global t colNames numCols myFirstFile

	set myFirstFile [tk_getOpenFile]

	# puts stdout [format "%s:myFirstFile=<%s>" $fn $myFirstFile]

	set fileID [open $myFirstFile r]

	# fetch first line from the file - header names
	set firstLine [getFirstLineFromFile $myFirstFile]

	# split first line into column names
	set colNames [split $firstLine ,]
	
	# number of columns in the file
	set numCols [llength  $colNames ]
	#puts "Number of columns in $colNames is $numCols" 
	
	# populates the textarea with new information
	set i 1
	$t.text1 delete 1.0 end
	while { [gets $fileID line] >= 0 } {
		#puts stdout [format "line(%d)=%s" $i $line]
		$t.text1 insert end [format "%s\n" $line]
		incr i
		} ;

	close $fileID
} ; 

# proc to open second file
proc openFile2 {} {
	set fn "openFile2"
	global t mySecondFile

	set mySecondFile [tk_getOpenFile]

	#puts stdout [format "%s:myFile=<%s>" $fn $mySecondFile]

	set fileID [open $mySecondFile r]
	
	# populates the textarea with new information
	set i 1
	$t.text2 delete 1.0 end
	while { [gets $fileID line] >= 0 } {
		#puts stdout [format "line(%d)=%s" $i $line]
		$t.text2 insert end [format "%s\n" $line]
		incr i
		} ;

	close $fileID
};

# Selecting the columns with sensitive information
proc setSensitivityLevel {} {	
	global colNames welcomeFrame sensitivityLabelFrame myFirstFile mySecondFile
	
	set sensitivityLabelFrame ".sensitivityLabelFrame";
	set sensitivityFrame ".sensitivityFrame";
	
	# the data of the first file is split into individual columns
	splitIntoColumns $myFirstFile;
	# the data of the second file is split into individual columns
	splitIntoColns $mySecondFile;
	
	if {[winfo exists $sensitivityLabelFrame]} { destroy $sensitivityLabelFrame };
	frame $sensitivityLabelFrame -borderwidth 0 -background orange;
	
	if {[winfo exists $sensitivityFrame]} { destroy $sensitivityFrame };
	frame $sensitivityFrame -borderwidth 0 -background orange;
	
	# pack the welcome frame
	pack $welcomeFrame -side top -expand true -fill both 
	
	# widgets in the window
	# widget - upload file label
	label $sensitivityLabelFrame.lblColumns -text "Step 6 : Choose a penalty for each of the columns. Zero penalty makes the attribute Non-Sensitive. Higher the penalty, higher the Sensitivity" -background orange -compound left
	label $sensitivityLabelFrame.lblNote -text "Note - Quasi-identifiers are highlighted in red, and are defaulted to a penalty value of 70. This can be changed using the scale below." -background orange -compound left 
	label $sensitivityLabelFrame.lblBlank -text " " -background orange -compound left 
	pack $sensitivityLabelFrame.lblColumns $sensitivityLabelFrame.lblNote $sensitivityLabelFrame.lblBlank -padx 20 -side top
	
	label $sensitivityLabelFrame.lblColumnName -text "Low ------------------------------- Penalty -------------------------------- High" -background orange -compound left  
	pack $sensitivityLabelFrame.lblColumnName -padx 160 -side top -anchor nw
	
	global sw
	# Make a frame scrollable
	set sw [ScrolledWindow .sw]

	set sf [ScrollableFrame $sw.sf -background orange]

	$sw setwidget $sf

	set uf [$sf getframe]

	set i 0
	# Now fill the frame, resize the window to see the scrollbars in action 
    foreach x $colNames {
		global qiCheckbox$i
		set val [set qiCheckbox$i]	
		
		set checkbox$i 0
		#set c [checkbutton $sensitivityLabelFrame.checkbox$i -text $x -anchor nw -background orange];
		if {$val == 0} {
			set c [scale $uf.scale$i -label $x -activebackground black -orient horizontal -from 0 -to 100 -length 400 -tickinterval 10 -variable checkbox$i -background orange  -sliderrelief raised -width 8]
		} else {
 			set c [scale $uf.scale$i -label $x -activebackground black -orient horizontal -from 0 -to 100 -length 400 -tickinterval 10 -variable checkbox$i -background red  -sliderrelief raised -width 8]
			$uf.scale$i set 70
		}
		#pack $c -side top -anchor nw -expand false -padx 20 -pady 3;
		#puts "value of i here is $i"
		grid $c -row $i -column 1 -padx 160
		incr i
	}
	
	if {[winfo exists .buttonFrame]} { destroy .buttonFrame };
	frame .buttonFrame -borderwidth 0 -background orange;
	
	# widget - next step button
	button .buttonFrame.nextStep -text "Final Step - Analyze" -background lightgrey -command {analyze}
	pack .buttonFrame.nextStep -padx 20 -pady 20
	
	# destroy previous frame and pack new frame
	if {[winfo exists .qiLabelFrame]} { destroy .qiLabelFrame};
	global swo
	if {[winfo exists $swo]} { destroy $swo};
	pack $sensitivityLabelFrame -side top -expand 1 -fill both
	pack $sw -side top -expand 1 -fill both
	pack .buttonFrame -side top -expand 1 -fill both
};

# Group Quasi-Identifiers
proc setQuasiIdentifiers {} {	
	global colNames welcomeFrame qiLabelFrame myFirstFile mySecondFile 
	
	set qiLabelFrame ".qiLabelFrame";
	set qiFrame ".qiFrame";
	
	# the data of the first file is split into individual columns
	#splitIntoColumns $myFirstFile;
	# the data of the second file is split into individual columns
	#splitIntoColns $mySecondFile;
	
	if {[winfo exists $qiLabelFrame]} { destroy $qiLabelFrame };
	frame $qiLabelFrame -borderwidth 0 -background orange;
	
	if {[winfo exists $qiFrame]} { destroy $qiFrame };
	frame $qiFrame -borderwidth 0 -background orange;
	
	# pack the welcome frame
	pack $welcomeFrame -side top -expand true -fill both 
	
	# widgets in the window
	# widget - upload file label
	label $qiLabelFrame.lblColumns -text "Step 5 : Group the Quasi-Identifier Columns" -background orange -compound left
	label $qiLabelFrame.lblBlank1 -text " " -background orange -compound left
	label $qiLabelFrame.lblNote -text "Note - Select at least 2  Quasi Identifiers from the list below" -background orange -compound left
	label $qiLabelFrame.lblBlank2 -text " " -background orange -compound left	
	pack $qiLabelFrame.lblColumns $qiLabelFrame.lblBlank1 $qiLabelFrame.lblNote $qiLabelFrame.lblBlank2 -padx 20 -side top
	
	global swo
	# Make a frame scrollable
	set swo [ScrolledWindow .swo]

	set sfr [ScrollableFrame $swo.sfr -background orange]

	$swo setwidget $sfr

	set ufo [$sfr getframe]

	set i 0
	# Frame is filled with a list of checkboxes 
    foreach x $colNames {
		set qiCheckbox$i 0
		set c [checkbutton $ufo.qiCheckbox$i -text $x -anchor nw -background orange -compound left];
		#set c [scale $ufo.scale$i -label $x -orient horizontal -from 0 -to 100 -length 400 -showvalue 0 -tickinterval 10 -variable checkbox$i -background orange  -sliderrelief raised -width 8]
		#pack $c -side top -anchor nw -expand false -padx 20 -pady 3;
		#puts "value of i here is $i"
		grid $c -row $i -column 0 -padx 280 -pady 10
		incr i
	}
	
	if {[winfo exists .buttonFrame]} { destroy .buttonFrame };
	frame .buttonFrame -borderwidth 0 -background orange;
	
	# widget - next step button
	button .buttonFrame.nextStep -text "Next Step ->" -background lightgrey -command {setSensitivityLevel}
	pack .buttonFrame.nextStep -padx 20 -pady 20
	
	# destroy previous frame and pack new frame
	if {[winfo exists .metricFrame]} { destroy .metricFrame};
	pack $qiLabelFrame -side top -expand 1 -fill both
	pack $swo -side top -expand 1 -fill both
	pack .buttonFrame -side top -expand 1 -fill both
};

# select the metrics
proc setMetricList {} {
	global delimiterFrame metricList welcomeFrame metricFrame checkboxHidingFailure checkboxMissesCost checkboxLossMetric checkboxClassificationMetric checkboxDiscernibilityMetric delimiter
	
	set metricFrame ".metricFrame";
	if {[winfo exists $metricFrame]} { destroy $metricFrame };
	frame $metricFrame -borderwidth 10 -background orange;
	
	#sets the delimiter value
	setDelimiter;
	
	# pack the welcome frame
	pack $welcomeFrame -side top -expand true -fill both 
	
	# widgets in the window
	label $metricFrame.lblDelimiter -text "Step 4 : Select the metrics to be calculated" -background orange -compound left 
	label $metricFrame.lblNote -text "Note - If no metric is selected, both Hiding Failure and Misses Cost will be calculated" -background orange -compound left 
	label $metricFrame.lblBlank -text " " -background orange -compound left 
	pack $metricFrame.lblDelimiter $metricFrame.lblNote $metricFrame.lblBlank -padx 20

	# widget - checkbox list of metrics
	checkbutton $metricFrame.checkboxHidingFailure -text {Hiding Failure [calculates the percentage of sensitive information that can still be effectively discovered after sanitizing the data]} -anchor nw -background orange -compound left 
	checkbutton $metricFrame.checkboxMissesCost -text {Misses Cost [measures the percentage of non-sensitive information that is hidden after the sanitization process]} -anchor nw -background orange -compound left 
	#checkbutton $metricFrame.checkboxLossMetric -text {Loss Metric} -anchor nw -background orange -state disabled -compound left 
	#checkbutton $metricFrame.checkboxClassificationMetric -text {Classification Metric} -anchor nw -background orange -state disabled -compound left 
	#checkbutton $metricFrame.checkboxDiscernibilityMetric -text {Discernibility Metric} -anchor nw -background orange -state disabled -compound left 
	pack $metricFrame.checkboxHidingFailure $metricFrame.checkboxMissesCost -padx 20 -side top -expand 1 -fill both
	
	# widget - next step button
	button $metricFrame.nextStep -text "Next Step ->" -background lightgrey -command {setQuasiIdentifiers}
	pack $metricFrame.nextStep -padx 20 -pady 20 
	
	# destroy previous frames and pack new frame
	if {[winfo exists $delimiterFrame]} { destroy $delimiterFrame };
	pack $metricFrame -side top -expand true -fill both
}

# selecting the delimiter
proc getDelimiter {} {
	global delimiterFrame welcomeFrame delimiter
	
	# contains the delimiter, default set to comma
	set delimiter ","
	
	set delimiterFrame ".delimiterFrame";
	if {[winfo exists $delimiterFrame]} { destroy $delimiterFrame };
	frame $delimiterFrame -borderwidth 10 -background orange;
	
	# pack the welcome frame
	pack $::welcomeFrame -side top -expand true -fill both 
	
	# widgets in the window
	# widget - specify delimiter
	label $delimiterFrame.lblDelimiter -text "Step 3 : Specify a delimiter" -background orange -compound left 
	label $delimiterFrame.lblNote -text "Note - If nothing is specified below, the default delimiter is set to 'comma'" -background orange -compound left 
	label $delimiterFrame.lblBlank -text " " -background orange -compound left 
	pack $delimiterFrame.lblDelimiter $delimiterFrame.lblNote $delimiterFrame.lblBlank -padx 20

	# widget - delimiter entry field
	entry $delimiterFrame.entryDelimiter -width 10 -bd 2 -textvariable delimiter
	pack $delimiterFrame.entryDelimiter  -padx 20
	
	# widget - next step button
	button $delimiterFrame.nextStep -text "Next Step ->" -background lightgrey -command {setMetricList}
	pack $delimiterFrame.nextStep -padx 20 -pady 20
	
	# destroy previous frames and pack new frame
	if {[winfo exists .myArea]} { destroy .myArea };
	if {[winfo exists .browseButtonFrame]} { destroy .browseButtonFrame };
	if {[winfo exists .textAreaFrame]} { destroy .textAreaFrame };
	if {[winfo exists .nextButtonFrame]} { destroy .nextButtonFrame };
	pack $delimiterFrame -side top -expand true -fill both
}

proc setDelimiter {} {
	global delimiter delimiterFrame
	set delimiter [$delimiterFrame.entryDelimiter get]
}

proc displayHelpWindow {} {
	tk_dialog .dialog1 "Help" "Follow the steps in the tool and click the 'Next' button at the bottom when done" info 0 OK
}

proc displayAboutWindow {} {
	tk_dialog .dialog1 "About" "This program is a free software, created as part of a Masters program at Memorial University of Newfoundland in the year 2014.\n
This program is distributed in the hope that it will be useful, but comes with no warranty.\n
\n
Contributors : Vineet Karkera" info 0 OK
}

# setting up window
wm geometry . "1100x700+10+10"
# wm attributes . -fullscreen 1
wm title . "Privacy Preserving Algorithm Analysis Tool"

# setting up frame stuff
# splitting widgets into several frames in order to display them well
destroy .myArea .welcomeFrame .b .t .n .f
set f [frame .myArea -borderwidth 10 -background orange]
set welcomeFrame [frame .welcomeFrame -borderwidth 10 -background orange]
set b [frame .browseButtonFrame -borderwidth 10 -background orange]
set t [frame .textAreaFrame -borderwidth 10 -background orange]
set n [frame .nextButtonFrame -borderwidth 10 -background orange]

# widgets in the window
# widget - name of tool
label $welcomeFrame.border1 -text "----------------------------------------------" -background orange
pack $welcomeFrame.border1 -padx 20 -pady 5
label $welcomeFrame.lbl1 -text "Welcome to the Privacy Preserving Analysis tool" -background orange
label $welcomeFrame.border2 -text "----------------------------------------------" -background orange
pack $welcomeFrame.lbl1 -padx 20 -pady 5
pack $welcomeFrame.border2 -padx 20 -pady 5

# pack the welcome frame
pack $welcomeFrame -side top -expand true -fill both 

# widget - upload first file label
label $f.lbl2 -text "Step 1 : Upload File before Sanitization" -background orange -compound left -padx 15
# widget - upload sanitized file label
label $f.lbl3 -text "Step 2 : Upload Sanitized File" -background orange -compound left -padx 15
pack $f.lbl2 -padx 50 -side left
pack $f.lbl3  -padx 100 -side left

# widget - Browse button for first file
button $b.browse1 -text "Browse" -background lightgrey -command {openFile1}
# widget - Browse button for second file
button $b.browse2 -text "Browse" -background lightgrey -command {openFile2}

pack $b.browse1 -padx 120 -side left 
pack $b.browse2 -padx 170 -side left 

# widget - textArea
text $t.text1 -bd 2 -bg white -height 15 -width 40
text $t.text2 -bd 2 -bg white -height 15 -width 40
pack $t.text1 -padx 10 -pady 5 -side left
pack $t.text2 -padx 10 -pady 5 -side left

# widget - next step button
button $n.nextStep -text "Next Step ->" -background lightgrey -command {getDelimiter} -padx 15
pack $n.nextStep -padx 20 -pady 20 

# pack the entire frame containing labels
pack $f -side top -expand true -fill both 

# pack the entire frame containing browse buttons
pack $b -side top -expand true -fill both 

# pack the entire frame containing textareas
pack $t -side top -expand true -fill both 

# pack the entire frame containing button to go the next screen
pack $n -side top -expand true -fill both 

# lines within first text area box
$t.text1 insert end "Please upload a csv file from the menu\n" tag0
$t.text1 insert end "Or use the Browse button above...." tag1

# lines within the second text area box
$t.text2 insert end "Please upload a csv file from the menu\n" tag0
$t.text2 insert end "Or use the Browse button above.." tag1

# creates a menubar
menu .menubar
. config -menu .menubar

# creates a pull down menu with a label 
set File [menu .menubar.mFile]
.menubar add cascade -label File  -menu  .menubar.mFile

# creates a new pull down for quit
set Help [menu .menubar.help]
.menubar add cascade -label {Help} -menu  .menubar.help

# creates a new pull down for quit
set Quit [menu .menubar.quit]
.menubar add cascade -label {Quit} -menu  .menubar.quit

# options for the file drop down
$File add command -label {About} -command {displayAboutWindow}
$File add command -label {Help} -command {displayHelpWindow}
$File add command -label {Exit} -command exit

# options for the file drop down
$Help add command -label {Help} -command {displayHelpWindow}
$Help add command -label {About} -command {displayAboutWindow}

# options for the second drop down
$Quit add command -label {Yes, I want to leave!} -command exit
$Quit add command -label {No, I'll stay.}

# start of barchart code
proc 3drect {w args} {
    if [string is int -strict [lindex $args 1]] {
        set coords [lrange $args 0 3]
    } else {
        set coords [lindex $args 0]
    }
    foreach {x0 y0 x1 y1} $coords break
    set d [expr {($x1-$x0)/3}]
    set x2 [expr {$x0+$d+1}]
    set x3 [expr {$x1+$d}]
    set y2 [expr {$y0-$d+1}]
    set y3 [expr {$y1-$d-1}]
    set id [eval [list $w create rect] $args]
    set fill [$w itemcget $id -fill]
    set tag [$w gettags $id]
    $w create poly $x0 $y0 $x2 $y2 $x3 $y2 $x1 $y0 -outline black
    $w create poly $x1 $y1 $x3 $y3 $x3 $y2 $x1 $y0 -outline black -tag $tag
}

proc bars {w data} {
    set vals 0 
	set high 100
	set low 0
    set x0 40
	set y0 50 
	set x1 240 
	set y1 230 
	foreach bar $data {
        lappend vals [lindex $bar 1]
    }
	set f 2.1
    set x [expr $x0+30]
    set dx [expr ($x1-$x0-$x)/[llength $data]]
    set y3 [expr $y1-20]
    set y4 [expr $y1+10]
    $w create poly $x0 $y4 [expr $x0+30] $y3  $x1 $y3 [expr $x1-20] $y4 -fill gray65
    set dxw [expr $dx*6/10]
    foreach bar $data {
        foreach {txt val col} $bar break
        set y [expr {round($y1-($val*$f))}]
        set y1a $y1
        set tag [expr {$val<0? "d": ""}]
        3drect $w $x $y [expr $x+$dxw] $y1a -fill $col -tag $tag
        $w create text [expr {$x+25}] [expr {$y-18}] -text $val
        $w create text [expr {$x+12}] [expr {$y1a+2}] -text $txt -anchor n
        incr x $dx
    }
    $w lower d
}

proc createBarChart {} {
	global missesCost hidingFailure checkboxHidingFailure checkboxMissesCost
		
	# destroy previous frame and packs the new frame
	if {[winfo exists .sensitivityLabelFrame]} { destroy .sensitivityLabelFrame };
	pack [canvas .c -width 240 -height 280  -background orange -highlightthickness 0] -side left -expand true -fill both
	if { $checkboxHidingFailure == 1 && $checkboxMissesCost == 1} {
		bars .c "
			{{HF} [format "%.2f" $hidingFailure] red}
			{{MC} [format "%.2f" $missesCost] yellow}
		"
	} elseif {$checkboxHidingFailure == 1 && $checkboxMissesCost == 0} {
         bars .c "
			{{HF} [format "%.2f" $hidingFailure] red}
		"
	} elseif {$checkboxHidingFailure == 0 && $checkboxMissesCost == 1} {
         bars .c "
			{{MC} [format "%.2f" $missesCost] yellow}
		"
	} else {
         bars .c "
			{{HF} [format "%.2f" $hidingFailure] red}
			{{MC} [format "%.2f" $missesCost] yellow}
		"
    }
	
	.c create text 120 10 -anchor nw -text "Bar Chart"
}
# end of barchart code