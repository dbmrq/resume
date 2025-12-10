#!/usr/bin/env python3
"""Generate CV files from cv-data.yaml."""

import yaml
import sys
from pathlib import Path

ICON_ORDER = ['appstore', 'linkedin', 'github', 'whatsapp', 'email', 'print', 'download']

ICONS = {
    'appstore': ('App Store', 22, '0 0 24 24', '<path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>'),
    'linkedin': ('LinkedIn', 17, '0 0 24 24', '<path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>'),
    'github': ('GitHub', 19, '0 0 24 24', '<path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>'),
    'whatsapp': ('WhatsApp', 18, '0 0 90 90', '<path d="M 76.735 13.079 C 68.315 4.649 57.117 0.005 45.187 0 C 20.605 0 0.599 20.005 0.589 44.594 c -0.003 7.86 2.05 15.532 5.953 22.296 L 0.215 90 l 23.642 -6.202 c 6.514 3.553 13.848 5.426 21.312 5.428 h 0.018 c 0.001 0 -0.001 0 0 0 c 24.579 0 44.587 -20.007 44.597 -44.597 C 89.789 32.713 85.155 21.509 76.735 13.079 z M 27.076 46.217 c -0.557 -0.744 -4.55 -6.042 -4.55 -11.527 c 0 -5.485 2.879 -8.181 3.9 -9.296 c 1.021 -1.115 2.229 -1.394 2.972 -1.394 s 1.487 0.007 2.136 0.039 c 0.684 0.035 1.603 -0.26 2.507 1.913 c 0.929 2.231 3.157 7.717 3.436 8.274 c 0.279 0.558 0.464 1.208 0.093 1.952 c -0.371 0.743 -0.557 1.208 -1.114 1.859 c -0.557 0.651 -1.17 1.453 -1.672 1.952 c -0.558 0.556 -1.139 1.159 -0.489 2.274 c 0.65 1.116 2.886 4.765 6.199 7.72 c 4.256 3.797 7.847 4.973 8.961 5.531 c 1.114 0.558 1.764 0.465 2.414 -0.279 c 0.65 -0.744 2.786 -3.254 3.529 -4.369 c 0.743 -1.115 1.486 -0.929 2.507 -0.558 c 1.022 0.372 6.5 3.068 7.614 3.625 c 1.114 0.558 1.857 0.837 2.136 1.302 c 0.279 0.465 0.279 2.696 -0.65 5.299 c -0.929 2.603 -5.381 4.979 -7.522 5.298 c -1.92 0.287 -4.349 0.407 -7.019 -0.442 c -1.618 -0.513 -3.694 -1.199 -6.353 -2.347 C 34.934 58.216 27.634 46.961 27.076 46.217 z"/>'),
    'email': ('Email', 20, '0 0 24 24', '<path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>'),
    'print': ('Print', 20, '0 0 24 24', '<path d="M19 8H5c-1.66 0-3 1.34-3 3v6h4v4h12v-4h4v-6c0-1.66-1.34-3-3-3zm-3 11H8v-5h8v5zm3-7c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-1-9H6v4h12V3z"/>'),
    'download': ('Download PDF', 20, '0 0 24 24', '<path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>'),
}


def format_date_range(dates, part_time=False):
    start, end = dates.get('start', ''), dates.get('end', '')
    date_str = f"{start}–{end}" if end else str(start)
    return date_str + " <br>(part-time)" if part_time else date_str


def generate_job_header(job):
    company, title = job.get('company', ''), job.get('title', '')
    role_level, url = job.get('role_level'), job.get('url')
    date_range = format_date_range(job.get('dates', {}), job.get('part_time', False))

    if url:
        link_icon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>'
        title_span = f'<span class="title-text"><a href="{url}" target="_blank" rel="noopener" class="heading-link">{company}{link_icon}</a> – {title}</span>'
    elif role_level:
        title_span = f'<span class="job-title">{company} – {title} <span class="role-detail">({role_level})</span></span>'
    else:
        title_span = f'<span class="job-title">{company} – {title}</span>'

    return f'## {title_span} <span class="date-range">{date_range}</span>'


def generate_achievements(achievements):
    if not achievements:
        return ""
    lines = ["\n### Key Achievements"]
    for a in achievements:
        lines.append(f"- **{a.get('label', '')}:** {a.get('text', '')}")
    return "\n".join(lines)


def generate_cv(data):
    lines = [
        "---",
        f"name: {data['name']}",
        f"title: {data['title']}",
        "contact:",
        f"  - {data['location']}",
        '  - "{{EMAIL_LINK}}"',
        '  - "{{PHONE_LINK}}"',
        "---",
        "",
        "# Profile",
        data['profile'].strip(),
        "",
        "# Core Strengths & Skills",
    ]
    for skill in data.get('skills', []):
        lines.append(f"- **{skill['category']}:** {skill['items']}")
    lines.extend(["", "# Professional Experience", ""])

    for job in data.get('experience', []):
        lines.append(generate_job_header(job))
        if job.get('summary'):
            lines.append(job['summary'].strip())
        lines.append(generate_achievements(job.get('achievements')))
        lines.append("")

    if data.get('additional_experience'):
        lines.extend(["# Additional Experience", ""])
        for job in data['additional_experience']:
            lines.append(generate_job_header(job))
            if job.get('description'):
                lines.append(job['description'].strip())
            lines.append("")

    lines.append("# Education")
    for edu in data.get('education', []):
        degree, field, institution = edu.get('degree', ''), edu.get('field'), edu.get('institution', '')
        lines.append(f"- {degree}, {field} — {institution}" if field else f"- {degree} — {institution}")
    lines.append("")

    if data.get('languages'):
        lines.append("# Languages")
        lines.append(", ".join(f"{l['language']} ({l['level']})" for l in data['languages']))

    return "\n".join(lines)


def make_icon(icon_type, url=None, icon_id=None, onclick=None):
    title, size, viewbox, svg = ICONS[icon_type]
    id_attr = f' id="{icon_id}"' if icon_id else ''
    onclick_attr = f' onclick="{onclick}"' if onclick else ''
    href = url or '#'
    target = ' target="_blank" rel="noopener"' if url and url != '#' else ''
    return f'''<a href="{href}"{id_attr}{target}{onclick_attr} class="header-icon" title="{title}">
          <svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="{viewbox}" fill="currentColor">
            {svg}
          </svg>
        </a>'''


def generate_icons(data):
    links, contact = data.get('links', {}), data.get('contact', {})
    icons = []
    for icon_type in ICON_ORDER:
        if icon_type in links:
            icons.append(make_icon(icon_type, url=links[icon_type]))
        elif icon_type == 'whatsapp' and contact.get('phone'):
            icons.append(make_icon('whatsapp', url='#', icon_id='header-whatsapp'))
        elif icon_type == 'email' and contact.get('email'):
            icons.append(make_icon('email', url='#', icon_id='header-email'))
        elif icon_type == 'print':
            icons.append(make_icon('print', onclick='printPdf(); return false;'))
        elif icon_type == 'download':
            icons.append(f'''<a href="cv.pdf" download class="header-icon" title="Download PDF">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            {ICONS['download'][3]}
          </svg>
        </a>''')
    return '\n        '.join(icons)


def main():
    if len(sys.argv) < 2:
        print("Usage: generate.py [cv|icons]", file=sys.stderr)
        sys.exit(1)

    data_file = Path("cv-data.yaml")
    if not data_file.exists():
        print(f"Error: {data_file} not found", file=sys.stderr)
        sys.exit(1)

    with open(data_file, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    cmd = sys.argv[1]
    if cmd == 'cv':
        Path("cv.md").write_text(generate_cv(data), encoding='utf-8')
        print("Generated cv.md")
    elif cmd == 'icons':
        print(generate_icons(data))
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

