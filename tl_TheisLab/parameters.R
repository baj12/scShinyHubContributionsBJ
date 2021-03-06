# normalization parameters

# choice for the radio buttion
# cat(file = stderr(), "parameters1\n")
#     myNormalizationChoices <- list(dca_log = "dca_impute" #,
#                                   #equalize_gbms = "equalize_gbms"
#     )
tryCatch({
  # save(file = "test.RData", list = c(ls(), ls(envir = .GlobalEnv)))
  #    load(file = "test.RData")
  system("dca -h > /dev/null")
  myNormalizationChoices <- list(
    dca_log = "dca_impute" # ,
    # equalize_gbms = "equalize_gbms"
  )

  # value should be of class shiny.tag
  myNormalizationParameters <- list(
    dca_log = h4("no Parameters implemented")
    # ,
    # equalize_gbms = h4("no Parameters implemented")
  )
},
warning = function(e) {
  print("warning")
  myNormalizationChoices <<- c()
  myNormalizationParameters <<- list()
},
error = function(e) {
  print("error")
  myNormalizationChoices <<- c()
  myNormalizationParameters <<- list()
}
)

# cat(file = stderr(), "parameters2\n")


dca_impute <- reactive({
  if (DEBUG) cat(file = stderr(), "dca_impute\n")
  
  start.time <- base::Sys.time()
  on.exit({
    printTimeEnd(start.time, "dca_impute")
    if (!is.null(getDefaultReactiveDomain()))
      removeNotification(id = "dca_impute")
  })
  if (!is.null(getDefaultReactiveDomain())) {
    showNotification("dca_impute", id = "dca_impute", duration = NULL)
  }
  
  scEx <- scEx()

  if (is.null(scEx)) {
    if (DEBUG) {
      cat(file = stderr(), "dca_impute:NULL\n")
    }
    return(NULL)
  }
  if (.schnappsEnv$DEBUGSAVE) {
    save(file = "~/SCHNAPPsDebug/dca_impute.RData", list = c(ls(), ls(envir = globalenv())))
  }
  # load(file="~/SCHNAPPsDebug/dca_impute.RData")

  tfile <- tempfile(pattern = "dcaInput", tmpdir = tempdir(), fileext = ".csv")
  tdir <- paste0(tempdir(), "/dcaresults")
  resFile <- paste0(tdir, "/mean_norm.tsv")
  write.csv(x = as.matrix(assays(scEx)[[1]]), file = tfile)
  system(paste("dca", tfile, tdir))
  if (!file.exists(resFile)) {
    cat(file = stderr(), "dca_impute:failed\n")
    return(NULL)
  }
  newmat <- read.csv(resFile, sep = "\t", row.names = 1)

  colnames(newmat) <- colnames(scEx)
  # colnames(scEx) %in% colnames(newmat)
  sc_matrix = as.matrix(assays(scEx)[[1]])
  sc_matrix[rownames(newmat), colnames(newmat)] <- as.matrix(newmat[rownames(newmat), colnames(newmat)])
  sc_matrix[!rownames(newmat) %in% rownames(sc_matrix), ] <- 0
  if (DEBUG) {
    cat(file = stderr(), "dca_impute:Done\n")
  }

  scEx_bcnorm <- SingleCellExperiment(assay = list(logcounts = as(sc_matrix,"dgTMatrix")),
                                      colData = colData(scEx),
                                      rowData = rowData(scEx))
  
  x <- uniqTsparse(assays(scEx_bcnorm)[[1]])
  scalingFactor = 1000
  slot(x, "x") <- log(1 + slot(x, "x"), base = 2) * scalingFactor
  
  addClass("updateNormalization", "green")
  assays(scEx_bcnorm)[[1]] <- x
  return(scEx_bcnorm)

  
})



cat(file = stderr(), "parameters (Theislab) end\n")
