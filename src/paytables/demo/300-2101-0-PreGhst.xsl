<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>
			
			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;					
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param bingoColumns String of Bingo Symbols.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						var bingoCardData = (scenario.split("|")[0]).split(",");
						var drawnNumbers = (scenario.split("|")[1]).split(",");
						var bingoPatterns = (prizeNames.substring(1)).split(',');
						var patternWins = (prizeValues.substring(1)).split('|');
						
						// Define Bingo Constants, which may vary per game
						var bingoSymbols = ['B','I','N','G','O'];
						var prizePatterns = ["XXXXX,XXXXX,XXXXX,XXXXX,XXXXX","-XXXX,X-X--,-XXX-,--X-X,XXXX-","--XX-,-X--X,XXX--,-X---,XXXXX","--XXX,-X---,XXXX-,-X---,--XXX","X---X,-X-X-,--X--,-XXX-,--X--","--X--,-X-X-,X---X,-X-X-,--X--","X---X,-----,-----,-----,X---X"];
						var winPatterns = new Array(7);

						// convert prizePatterns to winPatterns
						for (var i = 0; i < prizePatterns.length; ++i)
						{
							var pattern = prizePatterns[i];
							pattern = pattern.replace(/,/g, "");
							winPatterns[i] = new Array();
							for (var j = 0; j < pattern.length; ++j)
							{
								if (pattern[j] == 'X')
								{
									winPatterns[i].push(j+1);
								}
							}
						}

						// convert wins to playPattern array
						var playPattern = new Array();
						for(var x = 0; x < bingoSymbols.length; ++x)
						{	
							for(var y = 0; y < bingoSymbols.length; ++y)
							{
								var data = bingoCardData[y * bingoSymbols.length + x];
								if((data == "FREE") || (checkMatch(drawnNumbers, data)))
								{
									playPattern.push(x * bingoSymbols.length + y + 1);
								}
							}
						}

						var winPrizeIndex = findPrize(winPatterns, playPattern);

						var index = 1;
						registerDebugText("Translation Table");
						while(index < translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}
						registerDebugText("Prize Table");
						for(var i = 0; i < bingoPatterns.length; ++i)
						{
							 registerDebugText("[" + i + "] -- Name: " + bingoPatterns[i] + ", Value: " + patternWins[i]);
						}
						
						var r = [];
						
						// Output Bingo Patterns
						/////////////////////////////
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;display:inline-block">');
							r.push('<tr><td class="tablehead" >');
							r.push(getTranslationByName("prizePatterns", translations));
							r.push('</td>');
							r.push('</tr>');
						r.push('</table>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" width="300" class="gameDetailsTable" style="table-layout:fixed;display:inline-block">');

							for(var pattern = 0; pattern < prizePatterns.length; ++pattern)
							{
								r.push('<tr><td class="tablebody" style="vertical-align:top">');
								
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed;display:inline-block">');
								r.push('<tr>');
								r.push('<td class="tablebody" colspan="' + prizePatterns.length + '">');
								r.push(getTranslationByName(bingoPatterns[pattern], translations));
								r.push('</td>');
								r.push('</tr>');

								r.push('<tr><td class="tablebody">');
								r.push(patternWins[pattern]);
								r.push('</td>');
								r.push('</tr>');

								r.push('</table>');
								r.push('</td>');

								r.push('<td class="tablebody">');
								r.push('<table border="1" cellpadding="2" cellspacing="0" class="gameDetailsTable" style="table-layout:fixed;display:inline-block">');
								for(var row = 0; row < bingoSymbols.length; ++row)
								{
									var rowSpots = prizePatterns[pattern].split(",")[row];
									r.push('<tr height="20">');
									for(var spot = 0; spot < bingoSymbols.length; ++spot)
									{
										r.push('<td class="tablebody" width="20" align="center">');
										if (rowSpots[spot] == 'X') 
										{
											r.push(rowSpots[spot]);
										}
										else
										{
											r.push('&nbsp');
										}

										r.push('</td>');
									}
									r.push('</tr>');
								}
								
								r.push('</table>');
								r.push('</td>');
								r.push('</tr>');
							}
						r.push('</table>');

						// OutputWinning Pattern
						////////////////////////////
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr><td class="tablehead" >');
							r.push(getTranslationByName("winningPattern", translations));
							r.push('<br>');
							//for (var i = 0; i < winPatterns.length; i++)
							//{
							//	r.push(winPatterns[i] + ' : ' + winPatterns[i].length);
							//	r.push('<br>');
							//}
							//r.push(playPattern);
							//r.push('<br>');
							if (winPrizeIndex > -1)
							{
								r.push(getTranslationByName(bingoPatterns[winPrizeIndex], translations));
							}
							else
							{
								r.push('&nbsp');
							}
							r.push('</td>');
							r.push('</tr>');
						r.push('</table>');
						r.push('&nbsp');

						// Output Bingo Card Data
						////////////////////////////
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr><td class="tablehead" colspan="' + bingoSymbols.length + '">');
						r.push(getTranslationByName("bingoCardNumbers", translations));
						r.push('</td>');
						r.push('</tr>');
						
						r.push('<tr>');
						for(var i = 0; i < bingoSymbols.length; ++i)
						{
							r.push('<td class="tablehead" align="center">');
							r.push(bingoSymbols[i]);
							r.push('</td>');
						}
						r.push('</tr>');
						
						for(var x = 0; x < bingoSymbols.length; ++x)
						{	
							var matches = [0,0,0,0,0];
							r.push('<tr>');
							for(var y = 0; y < bingoSymbols.length; ++y)
							{
								var data = bingoCardData[y * bingoSymbols.length + x];
								if(data == "FREE")
								{
									r.push('<td class="tablebody bold" rowspan="2" align="center">');
									r.push(getTranslationByName("freeSpace", translations));
								}
								else if(checkMatch(drawnNumbers, data))
								{
									r.push('<td class="tablebody bold" align="center">'); 
									r.push(data);
									matches[y] = true;
								}
								else
								{
									r.push('<td class="tablebody" rowspan="2" align="center">');
									r.push(data);
								}
								r.push('</td>');								
							}
							r.push('</tr>');
							r.push('<tr>');
							for(var y = 0; y < bingoSymbols.length; ++y)
							{
								if (matches[y])
								{
									r.push('<td class="tablebody bold" align="center">'); 
									r.push(getTranslationByName("matched", translations));
									r.push('</td>');
								}
							}
							r.push('</tr>');
						}
						r.push('</table>');
						r.push('&nbsp');
						
						// Output Drawn Numbers
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr><td class="tablehead" colspan="' + bingoSymbols.length + '">');
						r.push(getTranslationByName("drawnNumbers", translations));
						r.push('</td>');
						r.push('</tr>');
						
						for(var num = 0; num < 8; ++num)
						{
							r.push('<tr>');	
							for(var y = 0; y < bingoSymbols.length; ++y)
							{
								r.push('<td class="tablebody" align="center">');
								var data = drawnNumbers[y * 8 + num];
								r.push(data);
								r.push('</td>');
							}
							r.push('</tr>');	
						}
						r.push('</table>');
						
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}
					
					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					// Input: List of winning numbers and the number to check
					// Output: true is number is contained within winning numbers or false if not
					function checkMatch(winningNums, boardNum)
					{
						for(var i = 0; i < winningNums.length; ++i)
						{
							if(winningNums[i] == boardNum)
							{
								return true;
							}
						}
						
						return false;
					}

					function findPrize(Prizes,Board)
					{
						var i = 0;
						//var j;
						var retVal = -1;
						
						while (Prizes[i])
						{
							var j = 0;
							var foundPrize = true;
                            var eachPrize = Prizes[i];

							//while (Prizes[i,j])
							while (eachPrize[j])
							{
								//if (!contains(Board,Prizes[i,j]))
								if (!contains(Board,eachPrize[j]))
								{
									foundPrize = false;
									break;
								}
								j++;
							}
							if (foundPrize)
							{
								retVal = i;
								break;
							}
							i++;
						}
						return retVal;
					}

					function contains(a, obj) 
					{
						for (var i = 0; i < a.length; i++) 
						{
							if (a[i] === obj) 
							{
								return true;
							}
						}
						return false;
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
			
			<x:template match="prize" mode="PrizeValue">
				<x:text>|</x:text>
				<x:call-template name="Utils.ApplyConversionByLocale">
					<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
					<x:with-param name="code" select="/output/denom/currencycode" />
					<x:with-param name="locale" select="//translation/@language" />
				</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
