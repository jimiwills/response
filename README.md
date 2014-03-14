# README

## RESPONSE

Software for statistical analysis of differential cellular responses in multidimensional quantitative omics experiments.

## Purpose

This software targets a specific problem.  We have an experiment in which we treat different cancer model cell lines
with different drugs/hormone.  We then perform SILAC quantitative proteomics to compare each cell/condition with a pooled
standard.  In the end we have an experiment with 3 dimensions:

|      | Cell 1 | Cell 2 | Cell 2 | Cell 4 |
|-----|-----|-------|-------|------|
|Condition 1 | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 |
|Condition 2 | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 |
|Condition 3 | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 |
|Condition 4 | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 | | Replicates 1, 2 & 3 |

This software combines data from the replicate experiments (which have been processed using MaxQuant)
and estimates p-values and other statistics for each protein that summarize significant:

* disagreements between replicates
* differences between cell lines (within a condition)
* responses to conditions (within a cell line)
* differential responses to a condition between cell lines

in addition to summary statistics for each replicate, cell, condition, comparison.

## Key Facts

* Takes MaxQuant output and assesses
	* Reproduciblity between replicates
	* Reproducible responses to conditions
	* Reproducible differential responses between cell types
* Graphical user interface with
	* Processing options
	* Annotation options
	* Data filtering and statistical summary views
* Export to text file for further processing in your favourite analytical software



## Quick Start Guide

1. Run an experiment as outlined above.  Get familiar with MaxQuant (if you aren't already)

2. Label your experiments as follows in your experimentalDesign file:

	<cellname>.<conditionname>.<replicate>
	
	examples:
	
	LCC1.estrogen.rep1
	LCC1.estrogen.rep2
	LCC1.estrogen.rep3
	LCC1.control.rep1
	LCC1.control.rep2
	LCC1.control.rep3
	MCF7.estrogen.rep1
	MCF7.estrogen.rep2
	MCF7.estrogen.rep3
	MCF7.control.rep1
	MCF7.control.rep2
	MCF7.control.rep3
	
3. Run MaxQuant on your data (instructions can be found at [maxquant.org](http://www.maxquant.org/)).

4. Run Response (download from [github](https://github.com/response/response) as source or binary)

5. In the Processing panel (top left) choose your proteinGroups file, and a file to output to.

6. Choose a button... if you have an experiment like above, with multiple cells, multiple conditions, and multiple replicates, 
you can click the "All" button.

7. Go away and have a cuppa.  It could take a while.  The reason for this is that Response uses the Statistics::Reproducibility
module, which in turn uses a Theil Sen Estimator to perform regression on your data.  This approach calculates the gradients
between every possible pair of points (i.e. for 4000 proteins it would be 7998000 comparisons) before then calculating the median,
which requires then sorting that list (another potential 31983998001 comparisons, but luckily the Theil Sen Estimator module uses
C.A.R. Hoare's partition-based Quick Median method, which cuts the number of comparisons required).  This is all on Wikipedia, byt the way.  
Has it finished processing yet? ... 

8. Now in the Input Files for Analysis panel, your proteinGroups and output files are already selected, but you need to re-read the 
output file, so click the re-read button.

9. You can also load up a couple columns of annotation if you wish.  Then need to be in the same order as your proteinGroups file...
and in fact you can just copy the columns you want to use into another file using your favourite spreadsheet software.

10. After you load the files, a set of filters becomes available.  There are 3 sets.  

	* Columns - which columns to show.  These are different types of data, from different stages of the processing, plus annotatoins,
	and whether or not to show individual replicate data.  You can also choose to view summary statistics instead of individual protein
	data and you can flip the view (swap columns & rows)
	* Experiment - allows to focus in on paricular replicates and comparisons
	* Rows - allows to focus on particular proteins
	
11. After applying a filter and having a look at the data you can:

	* (left) click on the grid to show a menu, with the option of exporting this view (and other options)
	* click the '<' button next to the "Apply Filter" button to go back to the previous view.
	
12. If there are certain filters you find yourself using a lot, you can click the '+' button next to the filter to add it to the dropdown.
You can also add a name, by simply typing the name at the start of the filter, followed by a forward-slash (/)

	e.g.:  
	All (Flipped) / flip reps  data:SpreadPvalue|normalized|spread|ErrorOverSpreadPvalue|SpreadOverErrorPvalue|medians|DistanceToRegressionLine|ErrorPvalue procs:subtractMedian|source|deDiagonalize|rotateToRegressionLine pg:Contaminant|Reverse|Protein_names|Protein_IDs

13. Saved filters are saved in a config file.  They're also avalailable in the grid menu, as you can simultaneously filter based on a row
(e.g. select a single protein to view) and choose a column filter (e.g. the filter in the example above)

14. The SpreadOverErrorPvalue tells you how much your replicates agree with each other about a protein's regulation, compared to 
what would be expected by random.  It's a good place to start if you're searching for regulated proteins.

## Questions, complaints, requests, etc...

Please contact the authors with any feedback.