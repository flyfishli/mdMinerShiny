# Fuhai Li's lab; FuhaiLi@osumc.edu; Robert.fh.li@gmail.com;
if (1 == 2){  # How To: Run Shiny App
	dir1 <- c('/Users/li150/FHLosu/Projects/Shiny')
	setwd(dir1)
	library('shiny')
	runApp("mdMinerShiny")
}

if (1 == 2){  # required R packages/libraries
	library(shiny)
	library(networkD3)
	library(DT)
	library(igraph)
}

if (1 == 2){  # for debuging: 
	wDir <- c('/Users/li150/FHLosu/Projects/Shiny/mdMinerShiny/')
	setwd(wDir)
	source('./pmShiny.R')
	f1 <- c("./dataDemo/foldchangePc3.txt")
	x1 <- read.table(f1, header=F, sep='\t')  # x1 variable has the data
	x1 <- as.matrix(x1)  # conver the list format into matrix format

	gSym <- as.character(x1[,1])  # get the gene Symbols
	fc <- as.numeric(x1[,2])  # get the value of fold change
	x = getPersonalNet1(fc, gSym);
}

# 1) install R packages
# library(org.Hs.eg.db)
# library(graphite)
# library(igraph)

# 2) read in the fold change data
# f1 <- c("path to fold change file/file name")  # fiel name: for example: 


# interface-1:
getPersonalNet1 <- function(fc, gSym){  # it is used an interface
	f1 <- c('./DiseaseGenes/DiseaseGenesProstate.txt')
	rootGenes <- read.table(f1, sep='\t')
	rootGenes <- as.character(rootGenes[[1]])
	
	f1 <- c('./dataCommon/tfTarget.txt')
	tfTar0 <- read.table(f1, header=F, sep='\t')
	tfTar0 <- as.matrix(tfTar0)

	net1 <- getPersonalNetBioGrid1(fc, gSym, rootGenes, tfTar0)
	return(net1)
}

# interface-2:
getRepositionDrugs <- function(netPatient, n1){
	dir1 <- c("./drugMoaNetsUsing/")
	# dir1 <- c("./drugMoaNetsBioGridPrestwick402/")  #402 drugs in both lincs and prestwick+cliff'lab= in total 1398 drugs
	drugList <- dir(dir1)
	drugName <- gsub('.txt', '', drugList)
	nDrug <- length(drugList)

	ds <- rep(-1.0, nDrug)
	for (i in 1:nDrug){
		netDrug <- read.table(paste(dir1, drugList[i], sep='/'), header=F, sep='\t')
		ds[i] <- getDrugRepositionScore(netPatient, netDrug)
	}
	idx <- order(ds, decreasing=T)
	ds <- ds[idx]
	drugName <- drugName[idx]

	n1 <- min(n1, nDrug)
	dat <- cbind(drugName[1:n1], ds[1:n1])

	return(dat)  # drug name + score of sensitivity
}



#fDrugMoa <- c('./drugMoaNets/')
getRepositionDrugsV2 <- function(netPatient, n1){
	#dir1 <- c("/Users/li150/FHLosu/Projects/lincs/drugMoaNets/")
	dir1 <- c("./drugMoaNetsUsing/")
	drugList <- dir(dir1)
	drugName <- gsub('.txt', '', drugList)
	nDrug <- length(drugList)

	ds <- rep(-1.0, nDrug)
	for (i in 1:nDrug){
		netDrug <- read.table(paste(dir1, drugList[i], sep='/'), header=F, sep='\t')
		ds[i] <- getDrugRepositionScore(netPatient, netDrug)
	}
	idx <- order(ds, decreasing=T)
	ds <- ds[idx]
	drugName <- drugName[idx]

	n1 <- min(n1, nDrug)
	dat <- cbind(drugName[1:n1], ds[1:n1])

}

getDrugRepositionScore <- function(netPatient, netDrug){
	node0 <- union(netPatient[,1], netPatient[,2])
	node1 <- union(netDrug[,1], netDrug[,2])
	s <- length(intersect(node0, node1))/length(node0)

	return(s)
}

# sub-func: 
# sub-func: 048
removeDoubleEdge <- function(net1){  # remove the double-edge in the driver signaling network (i.e., A->B, and B->A)

	nEdge <- dim(net1)[1]
	idx1 <- rep(FALSE, nEdge)

	for (i in 1:(nEdge-1)){
		a1 <- net1[i,1]
		b1 <- net1[i,2]
		for (j in (i+1):nEdge){
			a2 <- net1[j,2]
			b2 <- net1[j,1]
			if (a1 == a2 & b1 == b2){
				idx1[j] <- TRUE
			}
		}
	}
	idx2 <- which(idx1 == TRUE)
	if (length(idx2)>0){
		net2 <- net1[-idx2, ]
	} else {
		net2 <- net1
	}
	return(net2)
}

# sub-func: ....
getPersonalNet2 <- function(fc, gSym, rootGenes){
	
	options(warn = -1)
	library(igraph)

	eKegg <- getKeggNet1(gSym)
	eKegg <- eKegg[,c(1,2)]  #only source/target information
	gTmp <- graph.edgelist(eKegg)  # build the background network with kegg edges

	nKegg <- union(eKegg[,1], eKegg[,2]) 

	tf1 <- getActiveTF3(fc, gSym)
	tf1 <- nKegg[nKegg %in% tf1]
	tf1 <- tf1[3]

	#get the root genes:
	# rootGenes <- read.table('./rootGenes.txt', header=F)
	# rootGenes <- as.character(rootGenes[[1]])
	rootGenes <- nKegg[nKegg %in% rootGenes]

	if (length(rootGenes) < 1){
		net1 <- matrix('test', 2,2)
		return(net1)
	}
	# get the KEGG background network
	net1 <- linkNodes1(gTmp, rootGenes, tf1)  #net1 is the network: source (1 column) and target node (2 column)

	# display the net1
	return(net1)
}

# ...
getPersonalNetBioGrid1 <- function(fc, gSym, rootGenes, tfTar0){
	
	options(warn = -1)
	library(igraph)
	
	f1 <- c("./network/BIOGRID-ALL-3.4.130.tab2-Symbol.txt")
	bNet.e <- read.table(f1, header=F, sep='\t', colClasses='character')
	# bNet.e <- bNet.e[,c(1,4)]
	bNet.e <- as.matrix(bNet.e)
	bNet.e <- bNet.e[-which(bNet.e[,1] == bNet.e[,2]),]

	eKegg <- bNet.e

	eKegg <- eKegg[,c(1,2)]  #only source/target information
	gTmp <- graph.edgelist(eKegg)

	nKegg <- union(eKegg[,1], eKegg[,2]) 

	nTar <- 3; T0 <- 2.0;
	tf1 <- getActiveTF5(fc, gSym, nTar, T0, tfTar0)
	tf1 <- nKegg[nKegg %in% tf1]
	# print(tf1)
	# tf1 <- tf1[3]

	#get the root genes:
	# rootGenes <- read.table('./rootGenes.txt', header=F)
	# rootGenes <- as.character(rootGenes[[1]])
	rootGenes <- nKegg[nKegg %in% rootGenes]
	rootGenes <- rootGenes[1:30]

	# get the KEGG background network
	net1 <- linkNodes1(gTmp, rootGenes, tf1)  #net1 is the network: source (1 column) and target node (2 column)

	# tfTar0 <- read.table('./tfTarget.txt', header=F, sep='\t')
	# tfTar0 <- as.matrix(tfTar0)
	
	tfTar01 <- tfTar0[,1]
	tfTar02 <- tfTar0[,2]

	idx1 <- which(tfTar01 %in% gSym & tfTar02 %in% gSym)
	tfTar01 <- tfTar01[idx1]  # intersection with gSym2 in sequence data
	tfTar02 <- tfTar02[idx1]
	tfTar0 <- tfTar0[idx1,]

	idx1 <- which(tfTar01 %in% nKegg)
	tfTar01 <- tfTar01[idx1]  # intersection with KEGG genes
	tfTar02 <- tfTar02[idx1]
	tfTar0 <- tfTar0[idx1,]

	aTar <- gSym[fc >= T0]
	et <- tfTar0[tfTar01 %in% tf1 & tfTar02 %in% aTar, ]
	dim(et) <- c(length(et)/2, 2)
	net1 <- rbind(net1, et)

	net1 <- unique(net1)
	net1 <- removeDoubleEdge(net1)

	if (1 == 2){  # output disease associated genes of prostate cancer
		f1 <- c('./prostate associated genes 30.txt')
		x1 <- rootGenes
		dim(x1) <- c(6, 5)
		write.table(x1, f1, quote=F, sep='\t')

		f1 <- c('./prostate activated TFs.txt')
		x1 <- tf1
		dim(x1) <- c(6, 4)
		write.table(x1, f1, quote=F, sep='\t')

		f1 <- c('./prostate target genes of activated TFs.txt')
		x1 <- unique(et[,2])
		dim(x1) <- c(2, 4)
		write.table(x1, f1, quote=F, sep='\t')

		f1 <- c('./prostate PC3 KPnet-Sub.txt')
		x1 <- net1
		write.table(x1, f1, quote=F, col.names=F, row.names=F, sep='\t')

		# plot the network
		plotDriverNet2v2(net1, rootGenes, tf1)

	}

	# display the net1
	return(net1)
}

# ...
getPersonalNet1v1 <- function(fc, gSym){
	
	options(warn = -1)
	library(igraph)
	xt <- getKeggNet3()
	pathwayKegg <- xt$x
	nPathway <- length(pathwayKegg)

	eKegg <- xt$y
	eKegg <- eKegg[,c(1,2)]  #only source/target information
	gTmp <- graph.edgelist(eKegg)

	nKegg <- union(eKegg[,1], eKegg[,2]) 

	nTar <- 3; T0 <- 2.0;
	tf1 <- getActiveTF4(fc, gSym, nTar, T0)
	tf1 <- nKegg[nKegg %in% tf1]
	tf1 <- tf1[3]

	#get the root genes:
	rootGenes <- read.table('./rootGenes.txt', header=F)
	rootGenes <- as.character(rootGenes[[1]])
	rootGenes <- nKegg[nKegg %in% rootGenes]
	rootGenes <- rootGenes[1:30]

	# get the KEGG background network
	net1 <- linkNodes1(gTmp, rootGenes, tf1)  #net1 is the network: source (1 column) and target node (2 column)

	tfTar0 <- read.table('./tfTarget.txt', header=F, sep='\t')
	tfTar0 <- as.matrix(tfTar0)
	tfTar01 <- tfTar0[,1]
	tfTar02 <- tfTar0[,2]

	idx1 <- which(tfTar01 %in% gSym & tfTar02 %in% gSym)
	tfTar01 <- tfTar01[idx1]  # intersection with gSym2 in sequence data
	tfTar02 <- tfTar02[idx1]

	idx1 <- which(tfTar01 %in% nKegg)
	tfTar01 <- tfTar01[idx1]  # intersection with KEGG genes
	tfTar02 <- tfTar02[idx1]

	aTar <- gSym[fc >= T0]
	et <- tfTar0[tfTar01 %in% tf0 & tfTar02 %in% aTar, ]
	dim(et) <- c(length(et)/2, 2)
	net1 <- rbind(net1, et)

	# display the net1
	return(net1)
}

# ...
getPersonalNet1t <- function(fc, gSym){
	
	options(warn = -1)
	library(igraph)
	net0 <- matrix('test', 1, 2)

	pathwayKegg <- getKeggNet2()
	nPathway <- length(pathwayKegg)

	eKegg <- getKeggNet1(gSym)
	eKegg <- eKegg[,c(1,2)]  #only source/target information
	gTmp <- graph.edgelist(eKegg)  # build the background network with kegg edges

	nKegg <- union(eKegg[,1], eKegg[,2]) 

	nTar <- 3; T0 <- 2.0; beta1 <- 6;

	tf1 <- getActiveTF4(fc, gSym, nTar, T0)
	tf1 <- nKegg[nKegg %in% tf1]
	if (length(tf1) < 1){
		return(net0)
	}

	#get the root genes:
	rootGenes <- read.table('./rootGenes.txt', header=F)
	rootGenes <- as.character(rootGenes[[1]])
	rootGenes <- nKegg[nKegg %in% rootGenes]

	if (length(rootGenes) < 1){
		return(net0)
	}

	net0 <- matrix('test', 1, 2)
	vS <- 1.0/fc  # reverse of fold change;
	
	for (j in 1:nPathway){
		print(j)
		gTmp <- pathwayKegg[[j]]
		gTmp <- setEdgeWeight1(gTmp, gSym, vS, beta1)

		nodeTmp <- V(gTmp)$name
		root0 <- intersect(rootGenes, nodeTmp)
		tf0 <- intersect(tf1, nodeTmp) 
		if (length(root0) < 1 | length(tf0)<1){
			next
		}

		net1 <- linkNodes1(gTmp, root0, tf0)
		if (length(net1) > 1){
			dim(net1) <- c(length(net1)/2, 2)
			net0 <- rbind(net0, net1)
		}
	}
	if (length(net0) < 3){
		next
	}
	net0 <- net0[-1, ]
	net0 <- unique(net0)
	# display the net1
	return(net0)
}

setEdgeWeight1 <- function(gTmp, gSym1, vS, beta1){
	# set weight to gTmp
	v1 <- V(gTmp)$name
	eHead <- v1[head_of(gTmp, E(gTmp))]
	eTail <- v1[tail_of(gTmp, E(gTmp))]

	nE1 <- length(eHead)
	wE <- rep(1.1, nE1)

	for (ne in 1:nE1){
		x1 <- eHead[ne]
		x2 <- eTail[ne]
		y1 <- which(gSym1 %in% x1)
		y2 <- which(gSym1 %in% x2)

		if (length(y1) == 0 | length(y2) == 0){
			next
		} else {
			wE[ne] <- ((vS[y1])^beta1 + (vS[y2])^beta1)/2
		}
	}
	vt <- mean(wE)
	wE[wE == 1.1] <- vt
	E(gTmp)$weight <- wE
	#get.edge.attribute(gTmp, "weight")
	return(gTmp)
}

# ...
linkNodes2 <- function(gTmp, recTmp, tfTmp){
	#library(igraph)
	
	vTmp <- V(gTmp)$name
	nPath1 <- 0
	pathTmp <- matrix('test', 1,2)
	vt <- matrix('test', 1,2)

	nRecTmp <- length(recTmp)
	for (j in 1:nRecTmp){
		paths <- get.shortest.paths(gTmp, recTmp[j], tfTmp, mode='out')
		paths <- paths$vpath 
		nPath <- length(paths)
				
		if (nPath > 0){
			for (k in 1:nPath){
				pt <- paths[[k]]
				pt <- pt$name
				nPt <- length(pt)
				if (nPt < 2){
					next	
				}
				
				for (l in 1:(nPt-1)){
					#vt <- vTmp[c(pt[l], pt[l+1])]
					vt <- c(pt[l], pt[l+1])
					pathTmp <- rbind(pathTmp, vt) 	
				}
			}
		}
	}
	pathTmp <- pathTmp[-1,]
	return(pathTmp)
}

# ...
linkNodes1 <- function(gTmp, recTmp, tfTmp){
	#library(igraph)
	
	vTmp <- V(gTmp)$name
	nPath1 <- 0
	pathTmp <- matrix('test', 1,2)
	vt <- matrix('test', 1,2)

	nRecTmp <- length(recTmp)
	for (j in 1:nRecTmp){
		paths <- get.shortest.paths(gTmp, recTmp[j], tfTmp, mode='out')
		paths <- paths$vpath 
		nPath <- length(paths)
				
		if (nPath > 0){
			for (k in 1:nPath){
				pt <- paths[[k]]
				pt <- pt$name
				nPt <- length(pt)
				if (nPt < 2){
					next	
				}
				
				for (l in 1:(nPt-1)){
					#vt <- vTmp[c(pt[l], pt[l+1])]
					vt <- c(pt[l], pt[l+1])
					pathTmp <- rbind(pathTmp, vt) 	
				}
			}
		}
	}
	pathTmp <- pathTmp[-1,]
	return(pathTmp)
}

# ...
getKeggNet3 <- function(){
	library(org.Hs.eg.db)
	library(graphite)
	library(igraph)	
	
	entrezId <- names(as.list(org.Hs.egSYMBOL[]))
    eEntrez=lapply(kegg,function(x){return(nodes(x))})
	nSymbol=lapply(eEntrez,function(x){x=intersect(x,entrezId);unlist(as.list(org.Hs.egSYMBOL[x]))})  # node symbol

	eSymbol <- list()
	
	for (i in 1:length(kegg)){
		# print(i)
		# e1 <- as.matrix(edges(kegg[[i]]))  # check the 'attributes()'
		e1 <- as.matrix(kegg[[i]]@edges)
		e1 <- e1[e1[,1] %in% entrezId & e1[,2] %in% entrezId, ]

		dim(e1) <- c(length(e1)/4, 4)

		e1[,1] <- unlist(as.list(org.Hs.egSYMBOL[e1[,1]]))
		e1[,2] <- unlist(as.list(org.Hs.egSYMBOL[e1[,2]]))
		
		e2 <- e1[e1[,3] == "undirected",]  # convert 'undirected' to directed
		if (length(e2) > 0){
			dim(e2) <- c(length(e2)/4, 4)
			e2=e2[,c(2:1,3:4)]	
			e1 <- rbind(e1, e2)
		}
		eSymbol[[i]] <- e1[!duplicated(e1),]
	}
	
	names(eSymbol)=names(kegg)
	
	# add newest KEGG pathways
	ras=read.delim("./code/Ras signaling pathway.txt",header=F)
	tnf=read.delim("./code/tnf signaling pathway.txt",header=F)
	Rap1=read.delim("./code/Rap1 signaling pathway.txt",header=F)
	FoxO=read.delim("./code/FoxO signaling pathway.txt",header=F)
	cGMP=read.delim("./code/cGMP signaling pathway.txt",header=F)
	AMPK=read.delim("./code/AMPK signaling pathway.txt",header=F)

	add_path=c("ras","tnf","Rap1","FoxO","cGMP","AMPK")

	nPathway <- length(eSymbol)
	for (i in 1:6){
		eSymbol[[nPathway + i]]=as.matrix(get(add_path[i]))[,1:4]
		names(eSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
		nSymbol[[nPathway +i]]=unique(as.vector(as.matrix(get(add_path[i]))[,1:2]))
		names(nSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
	}

	n1 <- length(eSymbol)
	pathwayKegg <- {}  # 'Null'

	for (i in 1:n1){
		e1 <- eSymbol[[i]]
		dim(e1) <- c(length(e1)/4, 4)
		e1 <- e1[,c(1,2)]  #only source/target information
		dim(e1) <- c(length(e1)/2, 2)
		gTmp <- graph.edgelist(e1)  # build the background network with kegg edges
		pathwayKegg[[i]] <- gTmp
	}
	
	e1 <- eSymbol[[1]]
	for (i in 2:n1){
		e1 <- rbind(e1, eSymbol[[i]])
	}

	resData <- list(x=pathwayKegg, y=e1)
	return(resData)
}


# ...
getKeggNet2 <- function(){
	library(org.Hs.eg.db)
	library(graphite)
	library(igraph)	
	
	entrezId <- names(as.list(org.Hs.egSYMBOL[]))
    eEntrez=lapply(kegg,function(x){return(nodes(x))})
	nSymbol=lapply(eEntrez,function(x){x=intersect(x,entrezId);unlist(as.list(org.Hs.egSYMBOL[x]))})  # node symbol

	eSymbol <- list()
	
	for (i in 1:length(kegg)){
		# print(i)
		# e1 <- as.matrix(edges(kegg[[i]]))  # check the 'attributes()'
		e1 <- as.matrix(kegg[[i]]@edges)
		e1 <- e1[e1[,1] %in% entrezId & e1[,2] %in% entrezId, ]

		dim(e1) <- c(length(e1)/4, 4)

		e1[,1] <- unlist(as.list(org.Hs.egSYMBOL[e1[,1]]))
		e1[,2] <- unlist(as.list(org.Hs.egSYMBOL[e1[,2]]))
		
		e2 <- e1[e1[,3] == "undirected",]  # convert 'undirected' to directed
		if (length(e2) > 0){
			dim(e2) <- c(length(e2)/4, 4)
			e2=e2[,c(2:1,3:4)]	
			e1 <- rbind(e1, e2)
		}
		eSymbol[[i]] <- e1[!duplicated(e1),]
	}
	
	names(eSymbol)=names(kegg)
	
	# add newest KEGG pathways
	ras=read.delim("./code/Ras signaling pathway.txt",header=F)
	tnf=read.delim("./code/tnf signaling pathway.txt",header=F)
	Rap1=read.delim("./code/Rap1 signaling pathway.txt",header=F)
	FoxO=read.delim("./code/FoxO signaling pathway.txt",header=F)
	cGMP=read.delim("./code/cGMP signaling pathway.txt",header=F)
	AMPK=read.delim("./code/AMPK signaling pathway.txt",header=F)

	add_path=c("ras","tnf","Rap1","FoxO","cGMP","AMPK")

	nPathway <- length(eSymbol)
	for (i in 1:6){
		eSymbol[[nPathway + i]]=as.matrix(get(add_path[i]))[,1:4]
		names(eSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
		nSymbol[[nPathway +i]]=unique(as.vector(as.matrix(get(add_path[i]))[,1:2]))
		names(nSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
	}

	n1 <- length(eSymbol)
	pathwayKegg <- {}  # 'Null'

	for (i in 1:n1){
		e1 <- eSymbol[[i]]
		dim(e1) <- c(length(e1)/4, 4)
		e1 <- e1[,c(1,2)]  #only source/target information
		dim(e1) <- c(length(e1)/2, 2)
		gTmp <- graph.edgelist(e1)  # build the background network with kegg edges
		pathwayKegg[[i]] <- gTmp
	}

	return(pathwayKegg)
}

# ...
getKeggNet1 <- function(gSym1){
	library(org.Hs.eg.db)
	library(graphite)	
	
	entrezId <- names(as.list(org.Hs.egSYMBOL[]))
    eEntrez=lapply(kegg,function(x){return(nodes(x))})
	nSymbol=lapply(eEntrez,function(x){x=intersect(x,entrezId);unlist(as.list(org.Hs.egSYMBOL[x]))})  # node symbol

	eSymbol <- list()
	
	for (i in 1:length(kegg)){
		# print(i)
		# e1 <- as.matrix(edges(kegg[[i]]))  # check the 'attributes()'
		e1 <- as.matrix(kegg[[i]]@edges)
		e1 <- e1[e1[,1] %in% entrezId & e1[,2] %in% entrezId, ]

		dim(e1) <- c(length(e1)/4, 4)

		e1[,1] <- unlist(as.list(org.Hs.egSYMBOL[e1[,1]]))
		e1[,2] <- unlist(as.list(org.Hs.egSYMBOL[e1[,2]]))
		
		e2 <- e1[e1[,3] == "undirected",]  # convert 'undirected' to directed
		if (length(e2) > 0){
			dim(e2) <- c(length(e2)/4, 4)
			e2=e2[,c(2:1,3:4)]	
			e1 <- rbind(e1, e2)
		}
		eSymbol[[i]] <- e1[!duplicated(e1),]
	}
	
	names(eSymbol)=names(kegg)

	# add newest KEGG pathways
	ras=read.delim("./Ras signaling pathway.txt",header=F)
	tnf=read.delim("./tnf signaling pathway.txt",header=F)
	Rap1=read.delim("./Rap1 signaling pathway.txt",header=F)
	FoxO=read.delim("./FoxO signaling pathway.txt",header=F)
	cGMP=read.delim("./cGMP signaling pathway.txt",header=F)
	AMPK=read.delim("./AMPK signaling pathway.txt",header=F)

	add_path=c("ras","tnf","Rap1","FoxO","cGMP","AMPK")

	nPathway <- length(eSymbol)
	for (i in 1:6){
		eSymbol[[nPathway + i]]=as.matrix(get(add_path[i]))[,1:4]
		names(eSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
		nSymbol[[nPathway +i]]=unique(as.vector(as.matrix(get(add_path[i]))[,1:2]))
		names(nSymbol)[nPathway + i]=as.matrix(get(add_path[i]))[1,5]
	}

	n1 <- length(eSymbol)
	e1 <- eSymbol[[1]]
	for (i in 2:n1){
		e1 <- rbind(e1, eSymbol[[i]])
	}

	return(e1)

}

getActiveTF5 <- function(fc, gSym, nTar, T0, tfTar0, tf1, tar1){
	
	# identify the activated TFs
	idxt1 <- which(gSym %in% tar1)
	sTar1 <- fc[idxt1] # suppression (negative zscore) for drugs
	
	# tf1 <- unique(tfTar0[,1])
	nTf <- length(tf1)
	
	sTf <- rep(0, nTf)  # importance score of TF
	for (i in 1:nTf){
		str1 <- tf1[i]  # i-th TF
		str2 <- tfTar0[tfTar0[,1] == str1, 2]  #targets of given TF
		idxt2 <- which(tar1 %in% str2)
		st <- sTar1[idxt2]
		st1 <- st[order(st, decreasing=T)]
		nt1 <- min(nTar, length(st1))

		st1 <- st1[1:nt1]
		sTf[i] <- sum(st1)/nt1	
	}
	
	idxt1 <- order(sTf, decreasing=T)
	sTf <- sTf[idxt1]
	tf2 <- tf1[idxt1]

	idx <- which(sTf >= T0)
	if (length(idx) < 1){
		idx <- 1
	}

	tf2 <- tf2[idx]
	
	return(tf2)
}

# sub-functions: ...
getActiveTF5 <- function(fc, gSym, nTar, T0, tfTar0){
	
	# tfTar0 <- read.table('./tfTarget.txt', header=F, sep='\t')
	# tfTar0 <- as.matrix(tfTar0)

	# identify the activated TFs
	tar1 <- unique(tfTar0[,2])
	idxt1 <- which(gSym %in% tar1)
	tar1 <- gSym[idxt1]  # might be missed by previous versions of getActiveTF...
	
	sTar1 <- fc[idxt1] # suppression (negative zscore) for drugs
	
	tf1 <- unique(tfTar0[,1])
	nTf <- length(tf1)
	
	sTf <- rep(0, nTf)  # importance score of TF
	for (i in 1:nTf){
		str1 <- tf1[i]  # i-th TF
		str2 <- tfTar0[tfTar0[,1] == str1, 2]  #targets of given TF
		idxt2 <- which(tar1 %in% str2)
		st <- sTar1[idxt2]
		st1 <- st[order(st, decreasing=T)]
		nt1 <- min(nTar, length(st1))

		st1 <- st1[1:nt1]
		sTf[i] <- sum(st1)/nt1	
	}
	
	idxt1 <- order(sTf, decreasing=T)
	sTf <- sTf[idxt1]
	tf2 <- tf1[idxt1]

	idx <- which(sTf >= T0)
	if (length(idx) < 1){
		idx <- 1
	}

	tf2 <- tf2[idx]
	
	return(tf2)
}

# sub-functions: ...
getActiveTF4 <- function(fc, gSym, nTar, T0){
	
	tfTar0 <- read.table('./tfTarget.txt', header=F, sep='\t')
	tfTar0 <- as.matrix(tfTar0)

	# identify the activated TFs
	tar1 <- unique(tfTar0[,2])
	idxt1 <- which(gSym %in% tar1)
	tar1 <- gSym[idxt1]  # might be missed by previous versions of getActiveTF...
	
	sTar1 <- fc[idxt1] # suppression (negative zscore) for drugs
	
	tf1 <- unique(tfTar0[,1])
	nTf <- length(tf1)
	
	sTf <- rep(0, nTf)  # importance score of TF
	for (i in 1:nTf){
		str1 <- tf1[i]  # i-th TF
		str2 <- tfTar0[tfTar0[,1] == str1, 2]  #targets of given TF
		idxt2 <- which(tar1 %in% str2)
		st <- sTar1[idxt2]
		st1 <- st[order(st, decreasing=T)]
		nt1 <- min(nTar, length(st1))

		st1 <- st1[1:nt1]
		sTf[i] <- sum(st1)/nt1	
	}
	
	idxt1 <- order(sTf, decreasing=T)
	sTf <- sTf[idxt1]
	tf2 <- tf1[idxt1]

	idx <- which(sTf >= T0)
	if (length(idx) < 1){
		idx <- 1
	}

	tf2 <- tf2[idx]
	
	return(tf2)
}


getActiveTF3 <- function(fc, gSym){
	
	tfTar0 <- read.table('./tfTarget.txt', header=F, sep='\t')
	tfTar0 <- as.matrix(tfTar0)

	# identify the activated TFs
	tar1 <- unique(tfTar0[,2])
	idxt1 <- which(gSym %in% tar1)
	
	sTar1 <- fc[idxt1] # suppression (negative zscore) for drugs
	
	tf1 <- unique(tfTar0[,1])
	nTf <- length(tf1)
	
	sTf <- rep(0, nTf)  # importance score of TF
	for (i in 1:nTf){
		str1 <- tf1[i]  # i-th TF
		str2 <- tfTar0[tfTar0[,1] == str1, 2]  #targets of given TF
		idxt2 <- which(tar1 %in% str2)
		st <- sTar1[idxt2]
		st1 <- st[order(st, decreasing=T)]
		nt1 <- min(3, length(st1))
		st1 <- st1[1:nt1]
		sTf[i] <- sum(st1)/nt1	
	}
	
	idxt1 <- order(sTf, decreasing=T)
	sTf <- sTf[idxt1]
	tf2 <- tf1[idxt1]


	tf2 <- tf2[1:15]
	
	return(tf2)
}


# f1 <- paste(dirProject1, '/PC3/foldchangePc3.txt', sep='')
# write.table(fcPc3, f1, row.names=T, col.names=F, sep='\t')
# f1 <- paste(dirProject1, '/PC3/tfTarget.txt', sep='')
# write.table(tfTar0, f1, row.names=F, col.names=F, sep='\t')
# tfTar0 <- getTfTargetInteraction1(dirDat0)


