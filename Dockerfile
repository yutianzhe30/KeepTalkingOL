FROM barichello/godot-ci:4.6

WORKDIR /app

COPY . .

RUN mkdir -p /app/Export/

CMD ["godot", "--headless", "--export-release", "Web", "/app/Export/index.html"]
