#######################################
# Stop menu
#######################################
observeEvent(input$stop_radiant, {
  if (isTRUE(getOption("radiant.local"))) stop_radiant()
})

observeEvent(input$stop_radiant_rmd, {
  if (isTRUE(getOption("radiant.local"))) stop_radiant(rmd = TRUE)
})

stop_radiant <- function(rmd = FALSE) {
  ## quit R, unless you are running an interactive session
  if (interactive()) {
    ## flush input and r_data into Rgui or Rstudio
    isolate({
      toList(input) %>%
        {.$nav_radiant <- r_data$nav_radiant; .} %>%
        assign("r_state", ., envir = .GlobalEnv)

      assign("r_data", toList(r_data), envir = .GlobalEnv)

      stop_message <- "\nStopped Radiant. State available as r_state and r_data.\n"
      lib <- if ("radiant" %in% installed.packages()) "radiant" else "radiant.data"

      if (!is_empty(input$rmd_report)) {
        rmd_report <-
          paste0("```{r echo = FALSE}\nknitr::opts_chunk$set(comment=NA, echo = FALSE, cache=FALSE, message=FALSE, warning=FALSE)\nsuppressWarnings(suppressMessages(library(", lib, ")))\n#loadr('~/radiant.sessions/r_data.rda')\n```\n\n") %>%
          paste0(., input$rmd_report) %>% gsub("\\\\\\\\","\\\\",.) %>%
          cleanout(.)
        if (!rmd) {
          os_type <- Sys.info()["sysname"]
          if (os_type == 'Windows') {
            cat(rmd_report, file = "clipboard")
            stop_message %<>% paste0(., "Report content was copied to the clipboard.\n")
          } else if (os_type == "Darwin") {
            out <- pipe("pbcopy")
            cat(rmd_report, file = out)
            close(out)
            stop_message %<>% paste0(., "Report content was copied to the clipboard.\n")
          }
        }
      }
      ## removing r_environment and r_sessions
      if (exists("r_sessions")) rm(r_sessions, envir = .GlobalEnv)
      unlink("~/r_figures/", recursive = TRUE)
      sshhr(try(rm(help_menu, make_url_patterns, import_fs, init_data, envir = .GlobalEnv), silent = TRUE))
      message(stop_message)

      if (rstudioapi::isAvailable() && !is_empty(input$rmd_report) && rmd) {
        path <- file.path(normalizePath("~"),"radiant.sessions")
        saver(get("r_data", envir = .GlobalEnv), file = file.path(path, "r_data.rda"))
        stopApp(rstudioapi::insertText(rmd_report))
      } else {
        stopApp()
      }
    })
  } else {
    stopApp()
    q("no")
  }
}
