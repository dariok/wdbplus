<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:exist="http://exist.sourceforge.net/NS/exist"
   xmlns:err="http://www.w3.org/2005/xqt-errors"
   xmlns:api="https://github.com/dariok/wdbplus/api/schema/v1"
   exclude-result-prefixes="#all" version="3.0">
   
   <xsl:param name="title" />
   <xsl:param name="rest" />
   <xsl:param name="baseURL" />
   
   <xsl:template match="api:results[api:file]">
      <xsl:variable name="max" select="number(@total)" />
      <xsl:variable name="start" select="number(@start)" />
      <xsl:variable name="lastPage" select="@total idiv 25 * 25 + 1" />
      
      <div>
         <h1>Suchergebnisse für »<xsl:value-of select="@query"/>«</h1>
         <p>
            <xsl:if test="$start gt 1">
               <button data-query="{ @self }" data-start="{ 1 }" title="go to page">
                  <xsl:text>[1–</xsl:text>
                  <xsl:value-of select="min((25, $max))"/>
                  <xsl:text>]《</xsl:text>
               </button>
            </xsl:if>
            <xsl:if test="$max gt 50 and $start gt 50">
               <xsl:variable name="prevPage" select="($start idiv 25 - 1) * 25 + 1"/>
               <button data-query="{ @self }" data-start="{ $prevPage }" title="go to page">
                  <xsl:text>[</xsl:text>
                  <xsl:value-of select="$prevPage"/>
                  <xsl:text>–</xsl:text>
                  <xsl:value-of select="$prevPage + 24"/>
                  <xsl:text>]〈</xsl:text>
               </button>
            </xsl:if>
            
            <span>
               <xsl:choose>
                  <xsl:when test="@total and not(@start)" />
                  <xsl:when test="$max gt 0">
                     <xsl:text> – Treffer </xsl:text>
                     <xsl:value-of select="@start"/>
                     <xsl:text> bis </xsl:text>
                     <xsl:value-of select="if ( @start + 24 gt $max ) then $max else @start + 24"/>
                     <xsl:text> von insgesamt </xsl:text>
                     <xsl:value-of select="$max"/>
                     <xsl:text> Texten – </xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text> – keine Treffer – </xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </span>
            
            <xsl:if test="$max gt 25 and @start + 25 lt $max and $start + 25 lt $lastPage">
               <button data-query="{ @self }" data-start="{ @start + 25 }" title="go to page">
                  <xsl:text>〉[</xsl:text>
                  <xsl:value-of select="@start + 25"/>
                  <xsl:text>–</xsl:text>
                  <xsl:value-of select="if(@start + 49 lt $max) then @start + 49 else $max"/>
                  <xsl:text>]</xsl:text>
               </button>
            </xsl:if>
            <xsl:if test="$start lt $lastPage">
               <button data-query="{ @self }" data-start="{ $lastPage }" title="go to page">
                  <xsl:text>》[</xsl:text>
                  <xsl:value-of select="$lastPage"/>
                  <xsl:text>–</xsl:text>
                  <xsl:value-of select="@total"/>
                  <xsl:text>]</xsl:text>
               </button>
            </xsl:if>
         </p>
         <ul>
            <xsl:apply-templates/>
         </ul>
      </div>
   </xsl:template>
   
   <xsl:template match="api:results[api:fragment]">
      <div>
         <dl>
            <xsl:apply-templates />
         </dl>
      </div>
   </xsl:template>
   
   <xsl:template match="api:file">
      <xsl:variable name="id" select="substring-after(@id, 'resources/')" />
      <li>
         <a href="view.html?id={ $id }" title="go to document">
            <xsl:value-of select="@label"/>
         </a>
         <button class="loadSearchResult"
               data-file="{ $id }"
               data-link="{ @details }" title="Show results">⮯</button>
         <div id="{ $id }" class="results" style="display: none;"/>
      </li>
   </xsl:template>
   
   <xsl:template match="api:fragment">
      <xsl:variable name="xpath" select="@path => tokenize('/')"/>
      <dt>
         <xsl:choose>
            <xsl:when test="contains($xpath[last()], '#')">
               <a href="view.html?id={ substring-after(../@from, 'resources/') }#{ substring-after($xpath[last()], '#')}">
                  <xsl:value-of select="@path" />
               </a>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="@path"/>
            </xsl:otherwise>
         </xsl:choose>
      </dt>
      <xsl:apply-templates />
   </xsl:template>
   
  <xsl:template match="api:fragment/p">
    <dd>
      <span class="kwic">
         <xsl:apply-templates select="span[@class = 'previous']"/>
      </span>
      <span class="kwic match">
         <xsl:apply-templates select="span[@class = 'hi']"/>
      </span>
      <span class="kwic">
         <xsl:apply-templates select="span[@class = 'following']"/>
      </span>
    </dd>
  </xsl:template>
  
  <xsl:template match="tei:w | tei:pc">
    <xsl:choose>
      <xsl:when test="*:match">
        <span class="match">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="not(following-sibling::*[1][self::tei:pc][matches(., '[.,!?]')])">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
