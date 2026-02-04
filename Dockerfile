FROM squidfunk/mkdocs-material
RUN pip install mkdocs-macros-plugin
RUN pip install mkdocs-glightbox
RUN pip install mkdocs-enumerate-headings-plugin
RUN pip install mkdocs-minify-plugin