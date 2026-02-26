import sys
import os
import markdown
import tempfile
import subprocess

def convert_md_to_pdf(md_path, pdf_path):
    if not os.path.exists(md_path):
        print(f"Error: {md_path} not found")
        sys.exit(1)
        
    with open(md_path, "r", encoding="utf-8") as f:
        md_text = f.read()
        
    # Convert MD to HTML
    html = markdown.markdown(md_text, extensions=['tables', 'fenced_code'])
    
    # Add basic styling to make it look like a manual
    styled_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{ font-family: "Microsoft YaHei", sans-serif; line-height: 1.6; padding: 2em; max-width: 800px; margin: 0 auto; }}
            h1, h2, h3 {{ border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }}
            table {{ border-collapse: collapse; width: 100%; margin-bottom: 1em; }}
            th, td {{ border: 1px solid #dfe2e5; padding: 6px 13px; }}
            th {{ background-color: #f6f8fa; }}
            blockquote {{ border-left: 0.25em solid #dfe2e5; color: #6a737d; padding: 0 1em; margin-left: 0; }}
            .mermaid {{ display: none; }} /* Mermaid won't render natively this easily, skip it or add JS */
            code {{ background-color: rgba(27,31,35,.05); border-radius: 3px; font-size: 85%; margin: 0; padding: .2em .4em; }}
        </style>
    </head>
    <body>
        {html}
    </body>
    </html>
    """
    
    # Write to temp HTML file
    temp_html = os.path.join(tempfile.gettempdir(), 'temp_manual.html')
    with open(temp_html, 'w', encoding='utf-8') as f:
        f.write(styled_html)
        
    # Use MS Edge (which is built-in on Windows 10/11) to print to PDF headlessly
    print("Converting HTML to PDF via Edge...")
    edge_paths = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    ]
    
    edge_exe = None
    for p in edge_paths:
        if os.path.exists(p):
            edge_exe = p
            break
            
    if not edge_exe:
        print("Microsoft Edge not found. Cannot print to PDF.")
        sys.exit(1)
        
    cmd = [
        edge_exe,
        "--headless",
        "--disable-gpu",
        f"--print-to-pdf={os.path.abspath(pdf_path)}",
        "--no-pdf-header-footer",
        temp_html
    ]
    
    subprocess.run(cmd, check=True)
    print(f"Successfully created {pdf_path}")
    
    try:
        os.remove(temp_html)
    except:
        pass

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python md2pdf.py <input.md> <output.pdf>")
        sys.exit(1)
        
    convert_md_to_pdf(sys.argv[1], sys.argv[2])
