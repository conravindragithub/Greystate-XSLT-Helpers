<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet [
	<!ENTITY % entities SYSTEM "entities.ent">
	%entities;
	
	<!-- You need to set this to the name of the property/attribute on your event nodes that holds the "date" value -->
	<!ENTITY eventDate "eventStartDateTime">
]>
<?umbraco-package This is a dummy for the packageVersion entity - see ../lib/freezeEntities.xslt ?>
<?CalendarHelperVersion ?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:umb="urn:umbraco.library"
	xmlns:date="&dates-ns-uri;"
	xmlns:make="&nodeset-ns-uri;"
	exclude-result-prefixes="umb date make"
>

	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
	
<!-- :: Configuration :: -->
	<xsl:variable name="config" select="document('&config-file;')/calendar" />
	
	<!-- Remember you can grab this from somewhere else, if necessary -->
	<xsl:variable name="language" select="'da'" />

	<!-- Set this to false() if you want Sunday as the first day of a week -->
	<xsl:variable name="firstDayOfWeekIsMonday" select="true()" />
	
<!-- :: Variables (from config) :: -->
	<!-- Monthnames -->
	<xsl:variable name="months" select="$config/months[lang($language)]/month" />
	
	<!-- Weekdays -->
	<xsl:variable name="weekdays" select="$config/weekdays[lang($language)]/weekday" />
	
	<!-- The nodes that are processed to create the days -->
	<xsl:variable name="days" select="$config/days/*" />
	
<!-- :: Templates :: -->

	<!--
		Build a complete calendar - pass in a `date` if needed, otherwise shows current month.
		- Pass in a collection of `events` to have the calendar automatically apply templates
		  to them inside the cell that corresponds to their date.
		- Pass in `class` and/or `id` to add those attributes to the <table>.
		- Pass `false()` into `caption` to turn the caption off.
	-->
	<xsl:template name="BuildCalendar">
		<xsl:param name="date" select="&today;" /><!-- Default to today -->
		<xsl:param name="events" select="/.." /><!-- Default to an empty nodeset -->
		<xsl:param name="caption" select="true()" />
		<xsl:param name="firstDayOfWeekIsMonday" select="$firstDayOfWeekIsMonday" />
		<xsl:param name="selectedDate" />
		<xsl:param name="class" />
		<xsl:param name="id" />
		
		<!-- Calculate all the tricky bits -->
		<xsl:variable name="firstDayOfMonth" select="concat(substring($date, 1, 7), '-01')" />
		<xsl:variable name="weekdayFirstDayOfMonth" select="&day-in-week;" />
		<xsl:variable name="emptyDaysBeforeFirstInMonth">
			<xsl:choose>
				<xsl:when test="$firstDayOfWeekIsMonday and $weekdayFirstDayOfMonth = &SUNDAY;"><xsl:value-of select="6" /></xsl:when>
				<xsl:when test="$firstDayOfWeekIsMonday and $weekdayFirstDayOfMonth &gt; 1"><xsl:value-of select="$weekdayFirstDayOfMonth - 1 - number($firstDayOfWeekIsMonday)" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="$weekdayFirstDayOfMonth - 1" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="month" select="substring($date, 6, 2)" />
		<xsl:variable name="year" select="substring($date, 1, 4)" />
		<xsl:variable name="isLeapYear" select="($year mod 4 = 0) and (not($year mod 100 = 0) or ($year mod 400 = 0))" />
		<xsl:variable name="daysInMonth" select="$months[@id = $month]/@days + (1 * ($isLeapYear and $month = '02'))" />

		<!-- Let's go ... -->
		<table>
			<xsl:if test="$class"><xsl:attribute name="class"><xsl:value-of select="$class" /></xsl:attribute></xsl:if>
			<xsl:if test="$id"><xsl:attribute name="id"><xsl:value-of select="$id" /></xsl:attribute></xsl:if>

			<!-- Caption for the calendar -->
			<xsl:if test="$caption">
				<caption>
					<xsl:apply-templates select="$months[@id = $month]" mode="table-caption">
						<xsl:with-param name="date" select="$date" />
					</xsl:apply-templates>
				</caption>
			</xsl:if>
			
			<!-- Headers (day names) -->
			<thead>
				<xsl:call-template name="headers">
					<xsl:with-param name="firstDayOfWeekIsMonday" select="$firstDayOfWeekIsMonday" />
				</xsl:call-template>
			</thead>
			
			<!-- All the dates -->
			<tbody>
				<xsl:apply-templates select="$days[@id &lt;= $daysInMonth][position() &gt;= (7 - $emptyDaysBeforeFirstInMonth)][position() mod 7 = 1]" mode="week">
					<xsl:with-param name="selectedDate" select="$selectedDate" />
					<xsl:with-param name="last" select="$daysInMonth" />
					<!-- Only pass on the events of the month we're showing -->
					<xsl:with-param name="events" select="$events[starts-with(&eventDate;, substring($date, 1, 7))]" />
				</xsl:apply-templates>
			</tbody>
		</table>
	</xsl:template>
	
	<!-- Build a week (row) in the calendar -->
	<xsl:template match="day | dummy" mode="week">
		<xsl:param name="events" />
		<xsl:param name="selectedDate" />
		<!-- Need the $last param because following-sibling:: works in the document (so not constrained to the initial node-set created) -->
		<xsl:param name="last" />
		<tr>
			<xsl:apply-templates select=". | following-sibling::*[position() &lt; 7][@id &lt;= $last]" mode="day">
				<xsl:with-param name="events" select="$events" />
				<xsl:with-param name="selectedDate" select="$selectedDate" />
			</xsl:apply-templates>
			<!-- If we're in the last week/row we probably need to add some dummies after the last day -->
			<xsl:if test="@id + 6 &gt; $last">
				<xsl:apply-templates select="$days[position() &lt;= (current()/@id + 6) - $last]" mode="day" />
			</xsl:if>
		</tr>
	</xsl:template>
	
	<!-- Build a single day -->
	<xsl:template match="day" mode="day">
		<xsl:param name="events" />
		<xsl:param name="selectedDate" />
		<xsl:variable name="eventsOnThisDay" select="$events[substring(&eventDate;, 9, 2) = current()/@id]" />
		<td>
			<xsl:if test="$eventsOnThisDay"><xsl:attribute name="class">eventDay</xsl:attribute></xsl:if>
			<xsl:if test="number(@id) = number($selectedDate)">
				<xsl:attribute name="class">
					<xsl:text>selected</xsl:text>
					<xsl:if test="$eventsOnThisDay">
						<xsl:text> eventDay</xsl:text>
					</xsl:if>
				</xsl:attribute>				
			</xsl:if>

			<!-- Render any events for this day  -->
			<xsl:if test="$eventsOnThisDay">
				<xsl:apply-templates select="." mode="events">
					<xsl:with-param name="events" select="$eventsOnThisDay" />
				</xsl:apply-templates>
			</xsl:if>

			<!-- now output the date -->
			<xsl:value-of select="number(@id)" />
		</td>
	</xsl:template>

	<!-- Template for the events on a date -->
	<xsl:template match="day" mode="events">
		<xsl:param name="events" />
		<div class="events_today">
			<xsl:apply-templates select="$events">
				<xsl:sort select="&eventDate;" data-type="text" order="ascending" />
			</xsl:apply-templates>					
		</div>
	</xsl:template>
	
	<!-- Empty placeholder cell -->
	<xsl:template match="dummy" mode="day">
		<td class="empty">&#160;</td>
	</xsl:template>
	
	<!-- Table caption, e.g.: "December 1970" -->
	<xsl:template match="month" mode="table-caption">
		<xsl:param name="date" />
		<xsl:variable name="year" select="substring($date, 1, 4)" />
		<xsl:value-of select="concat(., ' ', $year)" />
	</xsl:template>
	
	<!-- Header cells with the weekdays -->
	<xsl:template name="headers">
		<xsl:param name="firstDayOfWeekIsMonday" />
		<tr>
			<xsl:if test="not($firstDayOfWeekIsMonday)">
				<th><xsl:value-of select="$weekdays[@id = &SUNDAY;]" /></th>
			</xsl:if>
			<xsl:for-each select="$weekdays[@id &gt; &SUNDAY;]">
				<th><xsl:value-of select="." /></th>
			</xsl:for-each>
			<xsl:if test="$firstDayOfWeekIsMonday">
				<th><xsl:value-of select="$weekdays[@id = &SUNDAY;]" /></th>
			</xsl:if>
		</tr>
	</xsl:template>
	
</xsl:stylesheet>