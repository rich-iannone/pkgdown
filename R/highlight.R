highlight_text <- function(text) {
  out <- downlit::highlight(text, classes = downlit::classes_pandoc())
  if (!is.na(out)) {
    pre(out, r_code = TRUE)
  } else {
    pre(escape_html(text))
  }
}

highlight_examples <- function(code, topic, env = globalenv()) {
  bg <- context_get("figures")$bg %||% NA
  withr::local_options(list(
    crayon.enabled = TRUE,
    crayon.colors = 256,
    device = function(...) ragg::agg_png(..., bg = bg)
  ))

  fig_save_topic <- function(plot, id) {
    name <- paste0(topic, "-", id)
    do.call(fig_save, c(list(plot, name), fig_settings()))
  }

  out <- downlit::evaluate_and_highlight(
    code,
    fig_save = fig_save_topic,
    env = child_env(env),
    output_handler = evaluate::new_output_handler(value = pkgdown_print)
  )
  pre(out, r_code = TRUE)
}

pre <- function(x, r_code = FALSE) {
  paste0(
    "<pre", if (r_code) " class='sourceCode r'", ">", "<code>",
    x,
    "</code>","</pre>"
  )
}