<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet [
	<!ENTITY % entities SYSTEM "entities.ent">
	%entities;
]>
<!--
	_MediaHelper.xslt
	
	Enables simple retrieval of media by handling the GetMedia() call and error-checking
-->
<?umbraco-package This is a dummy for the packageVersion entity - see ../lib/freezeEntities.xslt ?>
<?MediaHelperVersion ?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:umb="urn:umbraco.library"
	xmlns:get="&random-ns-uri;"
	xmlns:make="&nodeset-ns-uri;"
	xmlns:cropup="urn:Eksponent.CropUp"
	exclude-result-prefixes="umb get make cropup"
>

	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />

	<!-- Set this to true() if you're using the Eksponent.CropUp cropper -->
	<xsl:variable name="useCropUp" select="false()" />

	<!-- Set up some strings for later use -->
	<xsl:variable name="stringProxy">
		<defaultConfig>&config-file;</defaultConfig>
		<cropUpConfig>&cropUp-config-file;</cropUpConfig>
		<x>x</x>
	</xsl:variable>
	<xsl:variable name="strings" select="&makeNodeSetOfStrings;" />
	
	<xsl:variable name="configFileName" select="($strings/defaultConfig[not($useCropUp)] | $strings/cropUpConfig[$useCropUp])[1]" />

	<!-- Fetch cropping setup -->
	<xsl:variable name="configFile" select="document(normalize-space($configFileName))" />
	<xsl:variable name="croppingSetup" select="$configFile/crops/crop" />
	<xsl:variable name="cropUpSetup" select="$configFile/cropUp/croppings/add" />
	
	<!-- Template for any media that needs fetching - handles potential error -->
	<xsl:template match="*" mode="media">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="id" />
		<xsl:param name="size" />
		<xsl:variable name="mediaNode" select="&GetMediaFile;" />
		<xsl:apply-templates select="$mediaNode[not(error)]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="id" select="$id" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for DAMP (Digibiz Advanced Media Picker) content -->
	<xsl:template match="*[DAMP[@fullMedia]]" mode="media">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="id" />
		<xsl:param name="size" />
		<xsl:apply-templates select="DAMP/mediaItem/*[@id]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="id" select="$id" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for media that should be wrapped in a link - handles potential error -->
	<xsl:template match="*" mode="media.link">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="id" />
		<xsl:param name="size" />
		<xsl:variable name="mediaNode" select="&GetMediaFile;" />
		<xsl:variable name="thumbnail" select="concat(substring-before($mediaNode/umbracoFile, concat('.', $mediaNode/umbracoExtension)), '_thumb.jpg')" />
		<xsl:if test="not($mediaNode[error])">
			<a href="{$mediaNode/umbracoFile}">
				<xsl:if test="$class"><xsl:attribute name="class"><xsl:value-of select="$class" /></xsl:attribute></xsl:if>
				<img src="{$thumbnail}" alt="{$mediaNode/@nodeName}">
					<xsl:if test="$crop">
						<xsl:attribute name="src"><xsl:value-of select="$mediaNode/*/crops/crop[@name = $crop]/@url" /></xsl:attribute>
					</xsl:if>
				</img>
			</a>
		</xsl:if>
	</xsl:template>
	
	<!-- Template for any mediafolder that needs fetching - handles potential error -->
	<xsl:template match="*" mode="media.folder">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="size" />
		<xsl:variable name="mediaFolder" select="&GetMediaFolder;" />
		<xsl:apply-templates select="$mediaFolder[not(error)]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for DAMP folder content -->
	<xsl:template match="*[DAMP[@fullMedia]]" mode="media.folder">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="size" />
		<xsl:variable name="mediaFolder" select="&GetDAMPMediaFolder;" />
		<xsl:apply-templates select="$mediaFolder[not(error)]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for getting a random item from a mediafolder -->
	<xsl:template match="*" mode="media.random">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="size" />
		<xsl:param name="count" select="1" /><!-- Currently unused -->
		<xsl:variable name="mediaFolder" select="&GetMediaFolder;" />
		<xsl:variable name="randomNumber" select="floor(get:random() * (count($mediaFolder/*[@id])) + 1)" />
		
		<xsl:apply-templates select="$mediaFolder[not(error)]/*[@id][position() = $randomNumber]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for a Media Folder - default to rendering all images/files inside -->
	<xsl:template match="Folder">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="size" />
		<xsl:apply-templates select="*[@id]">
			<xsl:with-param name="class" select="$class" />
			<xsl:with-param name="crop" select="$crop" />
			<xsl:with-param name="size" select="$size" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Template for a Media Image -->
	<xsl:template match="Image">
		<xsl:param name="class" />
		<xsl:param name="crop" />
		<xsl:param name="id" />
		<xsl:param name="size" />
		<img src="{umbracoFile}" width="{umbracoWidth}" height="{umbracoHeight}" alt="{@nodeName}">
			<xsl:if test="$crop">
				<xsl:variable name="cropConfig" select="($croppingSetup[@name = $crop] | $cropUpSetup[@name = $crop] | $cropUpSetup[@alias = $crop])[1]" />
				<xsl:variable name="cropSize" select="concat($cropConfig/@size, $cropConfig/@width, $strings/x[$cropConfig/@width], $cropConfig/@height)" />
				<xsl:variable name="selectedCrop" select="*/crops/crop[@name = $crop]" />
				
				<!-- If the media XML contains the crop -->
				<xsl:if test="$selectedCrop">
					<xsl:attribute name="src"><xsl:value-of select="*/crops/crop[@name = $crop]/@url" /></xsl:attribute>
				</xsl:if>
				<!-- CropUp has its own extension to get the URL -->
				<xsl:if test="$useCropUp">
					<xsl:attribute name="src">
						<xsl:apply-templates select="." mode="cropUp.url">
							<xsl:with-param name="crop" select="$crop" />
						</xsl:apply-templates>
					</xsl:attribute>
				</xsl:if>

				<!-- Output the sizes (or clear them if none found) -->
				<xsl:attribute name="width"><xsl:value-of select="substring-before($cropSize, 'x')" /></xsl:attribute>
				<xsl:attribute name="height"><xsl:value-of select="substring-after($cropSize, 'x')" /></xsl:attribute>
				
			</xsl:if>
			<!-- $size can override original + cropped sizes -->
			<xsl:if test="$size">
				<xsl:attribute name="width"><xsl:value-of select="substring-before($size, 'x')" /></xsl:attribute>
				<xsl:attribute name="height"><xsl:value-of select="substring-after($size, 'x')" /></xsl:attribute>
			</xsl:if>
			<xsl:if test="$class"><xsl:attribute name="class"><xsl:value-of select="$class" /></xsl:attribute></xsl:if>
			<xsl:if test="$id"><xsl:attribute name="id"><xsl:value-of select="$id" /></xsl:attribute></xsl:if>
		</img>
	</xsl:template>
			
<!-- :: URL Templates :: -->
	<!-- Entry template -->
	<xsl:template match="*" mode="media.url">
		<xsl:param name="crop" />
		<xsl:variable name="mediaNode" select="&GetMediaFile;" />
		<xsl:apply-templates select="$mediaNode[not(error)]" mode="url">
			<xsl:with-param name="crop" select="$crop" />
		</xsl:apply-templates>
	</xsl:template>

	<!-- DAMP template -->
	<xsl:template match="*[DAMP[@fullMedia]]" mode="media.url">
		<xsl:param name="crop" />
		<xsl:apply-templates select="DAMP/mediaItem/*[@id]" mode="url">
			<xsl:with-param name="crop" select="$crop" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Safeguards for empty elements - need one for each mode -->
	<xsl:template match="*[not(normalize-space())]" mode="media">
		<!-- Render info to the developer looking for clues in the source, as to why nothing renders -->
		<xsl:comment>Missing Media ID in <xsl:value-of select="name()" /> on <xsl:value-of select="../@nodeName" /> (ID: <xsl:value-of select="../@id" />)</xsl:comment>
	</xsl:template>
	
	<xsl:template match="*[not(normalize-space())]" mode="media.url">
		<xsl:apply-templates select="." mode="media" /><!-- Redirect to the one above -->
	</xsl:template>
	
	<xsl:template match="*[not(normalize-space())]" mode="media.link">
		<xsl:apply-templates select="." mode="media" /><!-- Redirect to the one above -->
	</xsl:template>
	
	<xsl:template match="*[not(normalize-space())]" mode="media.folder" priority="0">
		<xsl:apply-templates select="." mode="media" /><!-- Redirect to the one above -->
	</xsl:template>
	
	<!-- URL Template for Images -->
	<xsl:template match="Image" mode="url">
		<xsl:param name="crop" />
		<xsl:choose>
			<xsl:when test="$crop and $useCropUp">
				<xsl:apply-templates select="." mode="cropUp.url">
					<xsl:with-param name="crop" select="$crop" />
				</xsl:apply-templates>
			</xsl:when>				
			<xsl:when test="$crop">
				<xsl:value-of select="*/crops/crop[@name = $crop]/@url" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="umbracoFile" />				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- (internal) URL Template for CropUp image -->
	<xsl:template match="Image" mode="cropUp.url">
		<xsl:param name="crop" />
		
		<xsl:variable name="cropConfig" select="($croppingSetup[@name = $crop] | $cropUpSetup[@name = $crop] | $cropUpSetup[@alias = $crop])[1]" />
		<xsl:variable name="cropSize" select="concat($cropConfig/@size, $cropConfig/@width, $strings/x[$cropConfig/@width], $cropConfig/@height)" />

		<xsl:variable name="cropUpArgs">
			<xsl:if test="not($cropConfig)"><xsl:value-of select="$crop" /></xsl:if>
			<xsl:value-of select="$cropConfig/@alias" />
		</xsl:variable>

		<!-- Call the extension -->
		<xsl:value-of select="&CropUpUrlByMediaId;" />
		
	</xsl:template>
	
</xsl:stylesheet>