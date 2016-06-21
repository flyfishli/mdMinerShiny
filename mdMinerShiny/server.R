library(shiny)
library(networkD3)
data(MisLinks)
data(MisNodes)

source("./Module_A.r");
shinyServer(function(input, output) {
	RNASeq <- reactive({
		result = NULL;
		parentURL = "https://tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/";
		URL = paste(parentURL, tolower(input$cancerType), sep = "");
		if (input$dataType == "RNA-seq") {
			URL = paste(URL, "/cgcc/unc.edu/illuminahiseq_rnaseqv2/rnaseqv2/", sep = "");
			URLcontent = getTCGA_URL(URL);
			dirURL = URLcontent$dir_url;
			level_3_URL = grep("Level_3", dirURL, value = TRUE);
			subURLcontent = getTCGA_URL(level_3_URL[length(level_3_URL)]);
			fileURL = subURLcontent$file_url;
			normalizedResultsURL = grep("rsem.genes.normalized_results", fileURL, value = TRUE);

			withProgress(message = 'Collecting samples', {
				n = 5;
				# n = length(normalizedResultsURL);
				for (j in 1:n) {
					incProgress(1/n, detail = paste(j, '/', n))
					x = read.table(normalizedResultsURL[j], skip=1);
					names(x)= c("Gene ID", "patient 1");
					if (is.null(result)) {
						result = x;
					} else {
						result = cbind(result, x[, 2]);
					}
				}
			})

			return(cor(result[sapply(result, is.numeric)]));			
		}

	})

	output$text <- renderText({
		paste("You are choosing the", input$dataType, "of", input$cancerType)
	})

	output$downloadData <- downloadHandler(
		filename = function() {
			paste(input$cancerType, '_', input$dataType, '.txt', sep='')
		},
		content = function(file) {
			write.table(RNASeq(), file, quote = FALSE, sep = "\t", na = "", col.names = FALSE, row.names = FALSE)
		}
	)

	output$force <- renderForceNetwork({
		x = read.table("example.txt");
		sourceName = x[, 1];
		targetName = x[, 2];
		name = unique(c(as.character(sourceName), as.character(targetName)));
		group = numeric(length(name)) + 1;
		size = numeric(length(name)) + 1;
		MisNodes = data.frame(name, group, size);

		source = c(match(sourceName[1], name) - 1);
		target = c(match(targetName[1], name) - 1);
		for (i in 2:length(sourceName)) {
			source = c(source, match(sourceName[i], name) - 1);
			target = c(target, match(targetName[i], name) - 1);
		}

		value = numeric(length(source)) + 1;
		MisLinks = data.frame(source, target, value);

		forceNetwork(Links = MisLinks, Nodes = MisNodes,
		            Source = "source", Target = "target",
		            Value = "value", NodeID = "name",
		            Group = "group", opacity = 1, opacityNoHover = 1);
	})

})