markdown_text <- function(text, pkg = list(), ...) {
  if (identical(text, NA_character_) || is.null(text)) {
    return(NULL)
  }

  md_path <- withr::local_tempfile()
  write_lines(text, md_path)
  markdown_path_html(md_path, ..., pkg = pkg)
}

markdown_text_inline <- function(text, pkg = list(), where = "<inline>", ...) {
  html <- markdown_text(text, pkg = pkg, ...)
  if (is.null(html)) {
    return()
  }

  children <- xml2::xml_children(xml2::xml_find_first(html, ".//body"))
  if (length(children) > 1) {
    abort(
      sprintf(
        "Can't use a block element here, need an inline element: \n %s \n%s",
        what = pkgdown_field(pkg = pkg, where),
        text
      )
    )
  }

  paste0(xml2::xml_contents(children), collapse="")
}

markdown_text_block <- function(text, pkg = list(), ...) {
  html <- markdown_text(text, pkg = pkg, ...)
  if (is.null(html)) {
    return()
  }

  children <- xml2::xml_children(xml2::xml_find_first(html, ".//body"))
  paste0(as.character(children, options = character()), collapse = "")
}

markdown_body <- function(path, strip_header = FALSE, pkg = list()) {
  xml <- markdown_path_html(path, strip_header = strip_header, pkg = pkg)

  # Extract body of html - as.character renders as xml which adds
  # significant whitespace in tags like pre
  transformed_path <- withr::local_tempfile()
  xml %>%
    xml2::xml_find_first(".//body") %>%
    xml2::write_html(transformed_path, format = FALSE)

  lines <- read_lines(transformed_path)
  lines <- sub("<body>", "", lines, fixed = TRUE)
  lines <- sub("</body>", "", lines, fixed = TRUE)

  structure(
    paste(lines, collapse = "\n"),
    title = attr(xml, "title")
  )
}

markdown_path_html <- function(path, strip_header = FALSE, pkg = list()) {
  html_path <- withr::local_tempfile()
  convert_markdown_to_html(path, html_path)
  xml <- xml2::read_html(html_path, encoding = "UTF-8")
  if (!inherits(xml, "xml_node")) {
    return(NULL)
  }

  # Capture heading, and optionally remove
  h1 <- xml2::xml_find_first(xml, ".//h1")
  title <- xml2::xml_text(h1)
  if (strip_header) {
    xml2::xml_remove(h1)
  }

  structure(xml, title = title)
}

markdown_to_html <- function(text, dedent = 4, bs_version = 3) {
  if (dedent) {
    text <- gsub(paste0("($|\n)", strrep(" ", dedent)), "\\1", text, perl = TRUE)
  }

  md_path <- withr::local_tempfile()
  html_path <- withr::local_tempfile()

  write_lines(text, md_path)
  convert_markdown_to_html(md_path, html_path)

  html <- xml2::read_html(html_path, encoding = "UTF-8")
  tweak_page(html, "markdown", list(bs_version = bs_version))
  html
}

convert_markdown_to_html <- function(in_path, out_path, ...) {
  if (rmarkdown::pandoc_available("2.0")) {
    from <- "markdown+gfm_auto_identifiers-citations+emoji+autolink_bare_uris"
  } else if (rmarkdown::pandoc_available("1.12.3")) {
    from <- "markdown_github-hard_line_breaks+tex_math_dollars+tex_math_single_backslash+header_attributes"
  } else {
    stop("Pandoc not available", call. = FALSE)
  }

  rmarkdown::pandoc_convert(
    input = in_path,
    output = out_path,
    from = from,
    to = "html",
    options = purrr::compact(c(
      if (!rmarkdown::pandoc_available("2.0")) "--smart",
      if (rmarkdown::pandoc_available("2.0")) c("-t", "html4"),
      "--indented-code-classes=R",
      "--section-divs",
      ...
    ))
  )

  invisible()
}
