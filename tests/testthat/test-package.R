
test_that("package_vignettes() doesn't trip over directories", {
  dir <- withr::local_tempdir()
  dir_create(path(dir, "vignettes", "test.Rmd"))
  file_create(path(dir, "vignettes", "test2.Rmd"))

  expect_equal(as.character(package_vignettes(dir)$file_in), "vignettes/test2.Rmd")
})

test_that("check_bootstrap_version() allows 3, 4 (with warning), and 5", {
  expect_equal(check_bootstrap_version(3), 3)
  expect_warning(expect_equal(check_bootstrap_version(4), 5))
  expect_equal(check_bootstrap_version(5), 5)
})

test_that("check_bootstrap_version() gives informative error otherwise", {
  expect_snapshot(check_bootstrap_version(1), error = TRUE)
})


# titles ------------------------------------------------------------------

test_that("multiline titles are collapsed", {
  rd <- rd_text("\\title{
    x
  }", fragment = FALSE)

  expect_equal(extract_title(rd), "x")
})

test_that("titles can contain other markup", {
  rd <- rd_text("\\title{\\strong{x}}", fragment = FALSE)
  expect_equal(extract_title(rd), "<strong>x</strong>")
})

test_that("titles don't get autolinked code", {
  rd <- rd_text("\\title{\\code{foo()}}", fragment = FALSE)
  expect_equal(extract_title(rd), "<code>foo()</code>")
})
