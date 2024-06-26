find_template <- function(type,
                          name,
                          ext = ".html",
                          templates_dir = NULL,
                          bs_version = 3) {

  paths <- template_candidates(
    type = type,
    name = name,
    ext = ext,
    templates_dir = templates_dir,
    bs_version = bs_version
  )
  existing <- paths[file_exists(paths)]

  if (length(existing) == 0) {
    abort(paste0("Can't find template for ", type, "-", name, "."))
  }
  existing[[1]]
}

# Used for testing
read_template_html <- function(type, name, templates_dir = NULL, bs_version = 3) {
  path <- find_template(
    type = type,
    name = name,
    templates_dir = templates_dir,
    bs_version = bs_version
  )
  xml2::read_html(path)
}

template_candidates <- function(type,
                                name,
                                ext = ".html",
                                templates_dir = NULL,
                                bs_version = 3) {

  paths <- c(
    templates_dir,
    path_pkgdown(paste0("BS", bs_version), "templates")
  )
  names <- c(paste0(type, "-", name, ext), paste0(type, ext))
  all <- expand.grid(paths, names)

  path(all[[1]], all[[2]])
}

# Find directory where custom templates might live:
# * path supplied in `template.path`
# * package supplied in `template.package`
# * templates in package itself
templates_dir <- function(pkg = list()) {
  template <- pkg$meta$template

  if (!is.null(template$path)) {
    # Directory specified in yaml doesn't exist, so eagerly error
    if (!dir_exists(template$path)) {
      abort(paste0("Can not find templates path ", src_path(template$path)))
    }
    path_abs(template$path, start = pkg$src_path)
  } else if (!is.null(template$package)) {
    path_package_pkgdown("templates", package = template$package, bs_version = pkg$bs_version)
  } else {
    path(pkg$src_path, "pkgdown", "templates")
  }
}
