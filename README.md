# Greystate XSLT Helpers

Miscellaneous XSLT files for use as included stylesheets to ease certain common tasks.

Hopefully, using these helpers you should be able to keep your XSLT clean and
readable, while offering a level of indirection for tasks that could require changes in
the low-level implementation, when moved from one system to another.

## Installation

An installable package is in the works but for now, you should grab the files in the `dist` folder and put them in the `xslt` folder
of your Umbraco installation.


## Basic usage

Using these helpers usually just require the same 2 steps:

1.	Include the file(s) in your main XSLT file using the include instruction:

	`<xsl:include href="_HelperFile.xslt" />`

2.	Perform one of the following actions:
	* Applying templates in a specific mode
	
		`<xsl:apply-templates select="$currentPage/pageImage" mode="media" />`
	
	* Calling a named template
	
		`<xsl:call-template name="PageinateSelection" />`
	
## Helpers

Each helper has its own README but here&#8217;s a quick rundown: 

### [Pagination Helper][PAGINATION]

A self-contained clip-on solution for pagination of node-sets.

> "Just add Pagination"

### [Grouping Helper][GROUPING]

Just like pagination - but for grouping sets into chunks of *n* elements.

### [Media Helpers][MEDIA]

A bunch of well-tested templates for handling Media items in Umbraco - if you've asked some of the following questions, this is definitely for you:

> How can I output Media files and/or folders from my XSLT macros?

> But I just want to render the image the user picked - why is it so hard???

> How do I output a specific crop version?


[PAGINATION]: https://github.com/greystate/Greystate-XSLT-Helpers/tree/master/paginationhelper
[GROUPING]: https://github.com/greystate/Greystate-XSLT-Helpers/tree/master/groupinghelper
[MEDIA]: https://github.com/greystate/Greystate-XSLT-Helpers/tree/master/mediahelpers