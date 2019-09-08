(
 (c-mode
  (eval .
        (setq-local company-clang-arguments (list (format "-I%s" (nth 0 (projectile-expand-paths '("src"))))))
        )))
