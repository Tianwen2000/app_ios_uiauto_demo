#!/usr/bin/env python3
from __future__ import annotations

import base64
import datetime as dt
import html
import json
import sys
from pathlib import Path


def load_json_lines(path: Path) -> list[dict]:
    records: list[dict] = []
    if not path.exists():
        return records

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            records.append({"status": "invalid_json", "error": f"{path.name} 中存在非法 JSON 行"})
    return records


def load_json_object(path: Path) -> dict | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def format_duration(duration_ms: int | None) -> str:
    if duration_ms is None:
        return "暂无"
    return f"{duration_ms} ms"


def format_timestamp(ts_ms: int | None) -> str:
    if ts_ms is None:
        return "暂无"
    return dt.datetime.fromtimestamp(ts_ms / 1000).astimezone().strftime("%Y-%m-%d %H:%M:%S")


def text_or_default(value: object | None, default: str = "暂无") -> str:
    if value is None:
        return default
    text = str(value).strip()
    return text or default


def status_text(status: object | None) -> str:
    mapping = {
        "passed": "通过",
        "failed": "失败",
        "invalid_json": "日志异常",
    }
    raw = text_or_default(status, "未知")
    return mapping.get(raw, raw)


def status_class(status: object | None) -> str:
    raw = text_or_default(status, "unknown")
    if raw == "passed":
        return "passed"
    if raw == "failed":
        return "failed"
    return "unknown"


def translate_test_name(name: object | None) -> str:
    raw = text_or_default(name)
    mapping = {
        "testSearchAndCategoryFilters": "搜索与分类筛选",
        "testSmoke_LoginBrowseProfileLogout": "登录、浏览、个人页校验并退出",
    }
    return mapping.get(raw, raw)


def translate_step_name(name: object | None) -> str:
    raw = text_or_default(name)
    mapping = {
        "Wait for login screen": "等待登录页出现",
        "Submit valid credentials": "提交有效账号密码",
        "Verify discover screen and search": "校验发现页并执行搜索",
        "Add a product to the cart": "将商品加入购物袋",
        "Open profile and validate state": "进入个人页并校验状态",
        "Toggle profile switches": "切换个人页开关项",
        "Logout back to login": "退出并返回登录页",
        "Login into the demo app": "登录进入演示应用",
        "Search for a matching product": "搜索命中的商品",
        "Clear search and filter by category": "清空搜索并按分类筛选",
        "Drive the empty state": "触发空状态页面",
    }
    return mapping.get(raw, raw)


def translate_action_name(name: object | None) -> str:
    raw = text_or_default(name)
    mapping = {
        "tap": "点击",
        "input": "输入",
        "type": "键入",
    }
    return mapping.get(raw, raw)


def image_src(run_dir: Path, relpath: str | None, inline_images: bool) -> str | None:
    if not relpath:
        return None

    image_path = run_dir / relpath
    if not image_path.exists():
        return relpath

    if not inline_images:
        return relpath

    suffix = image_path.suffix.lower()
    mime_type = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }.get(suffix, "application/octet-stream")

    encoded = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return f"data:{mime_type};base64,{encoded}"


def md_link(relpath: str | None, label: str) -> str:
    if not relpath:
        return "暂无"
    return f"[{label}]({relpath})"


def build_markdown(
    run_id: str,
    run_dir: Path,
    tests: list[dict],
    summary: dict,
    network_note: str,
    generated_at: str,
) -> str:
    lines: list[str] = [
        "# UI 自动化测试报告",
        "",
        f"- 运行ID: `{run_id}`",
        f"- 生成时间: {generated_at}",
        f"- 报告目录: `{run_dir}`",
        "",
        "## 总览",
        "",
        f"- 用例总数: {summary['tests']}",
        f"- 通过用例: {summary['passed']}",
        f"- 失败用例: {summary['failed']}",
        f"- 截图数量: {summary['screenshots']}",
        f"- JSONL 日志数量: {summary['jsonl_logs']}",
        f"- 失败步骤数: {summary['failed_steps']}",
        f"- 失败动作数: {summary['failed_actions']}",
        "",
        "## 用例详情",
        "",
    ]

    for test in tests:
        result = test["result"]
        lines.extend(
            [
                f"### {translate_test_name(test['name'])}",
                "",
                f"- 状态: {status_text(result.get('status'))}",
                f"- 耗时: {format_duration(result.get('duration_ms'))}",
                f"- 开始时间: {format_timestamp(result.get('started_at_ms'))}",
                f"- 结束时间: {format_timestamp(result.get('ended_at_ms'))}",
                f"- 失败步骤: {text_or_default(result.get('failure_step_id'))}",
                f"- 调试描述: {md_link(result.get('debug_description_relpath'), '查看调试描述')}",
                "",
                "| 步骤ID | 步骤名称 | 状态 | 耗时 | 截图 | 错误信息 |",
                "| --- | --- | --- | --- | --- | --- |",
            ]
        )

        for step in test["steps"]:
            lines.append(
                "| {step_id} | {step_name} | {status} | {duration} | {screenshot} | {error} |".format(
                    step_id=text_or_default(step.get("step_id"), "-"),
                    step_name=translate_step_name(step.get("step_name")),
                    status=status_text(step.get("status")),
                    duration=format_duration(step.get("duration_ms")),
                    screenshot=md_link(step.get("screenshot_relpath"), "查看截图"),
                    error=text_or_default(step.get("error"), "-").replace("\n", " "),
                )
            )

        failed_actions = [action for action in test["actions"] if action.get("status") != "passed"]
        lines.extend(["", "#### 失败动作", ""])
        if not failed_actions:
            lines.append("- 无")
        else:
            lines.extend(
                [
                    "| 步骤ID | 动作 | 目标 | 详情 | 错误信息 |",
                    "| --- | --- | --- | --- | --- |",
                ]
            )
            for action in failed_actions:
                lines.append(
                    "| {step_id} | {action_name} | {target} | {detail} | {error} |".format(
                        step_id=text_or_default(action.get("step_id"), "-"),
                        action_name=translate_action_name(action.get("action")),
                        target=text_or_default(action.get("target"), "-").replace("\n", " "),
                        detail=text_or_default(action.get("detail"), "-").replace("\n", " "),
                        error=text_or_default(action.get("error"), "-").replace("\n", " "),
                    )
                )
        lines.append("")

    lines.extend(
        [
            "## 接口采集说明",
            "",
            network_note,
            "",
            "## 备注",
            "",
            "- 本报告基于测试侧本地采集到的 JSONL、截图和结果文件生成。",
            "- `.xcresult` 仍保留，但不作为唯一证据来源，因为 Xcode 可能出现附件写入 warning。",
        ]
    )
    return "\n".join(lines) + "\n"


def build_step_cards(run_dir: Path, steps: list[dict], inline_images: bool) -> str:
    cards: list[str] = []
    for step in steps:
        screenshot = step.get("screenshot_relpath")
        screenshot_src = image_src(run_dir, screenshot, inline_images) if screenshot else None
        screenshot_html = (
            "<div class='shot-empty'>本步骤无截图</div>"
            if not screenshot
            else (
                "<button class='shot-button' type='button' "
                f"data-src='{html.escape(screenshot_src or screenshot)}' "
                f"data-caption='{html.escape(text_or_default(step.get('step_id'), '-'))} "
                f"{html.escape(translate_step_name(step.get('step_name')))}'>"
                f"<img src='{html.escape(screenshot_src or screenshot)}' alt='{html.escape(translate_step_name(step.get('step_name')))}' loading='lazy'>"
                "<span>点击查看大图</span>"
                "</button>"
            )
        )

        error_html = ""
        if step.get("error"):
            error_html = (
                "<div class='error-box'>"
                f"<strong>错误信息</strong><p>{html.escape(text_or_default(step.get('error')))}</p>"
                "</div>"
            )

        cards.append(
            "<article class='step-card'>"
            "<div class='step-header'>"
            f"<div class='step-id'>{html.escape(text_or_default(step.get('step_id'), '-'))}</div>"
            f"<div class='status-chip {status_class(step.get('status'))}'>{html.escape(status_text(step.get('status')))}</div>"
            "</div>"
            f"<h4>{html.escape(translate_step_name(step.get('step_name')))}</h4>"
            "<div class='meta-grid'>"
            f"<div><span>耗时</span><strong>{html.escape(format_duration(step.get('duration_ms')))}</strong></div>"
            f"<div><span>结束时间</span><strong>{html.escape(format_timestamp(step.get('ended_at_ms')))}</strong></div>"
            "</div>"
            f"{error_html}"
            "<div class='shot-wrapper'>"
            f"{screenshot_html}"
            "</div>"
            "</article>"
        )
    return "".join(cards) if cards else "<div class='empty-state'>暂无步骤数据</div>"


def build_failed_actions_table(actions: list[dict]) -> str:
    failed_actions = [action for action in actions if action.get("status") != "passed"]
    if not failed_actions:
        return "<div class='empty-state'>本用例没有失败动作</div>"

    rows: list[str] = []
    for action in failed_actions:
        rows.append(
            "<tr>"
            f"<td>{html.escape(text_or_default(action.get('step_id'), '-'))}</td>"
            f"<td>{html.escape(translate_action_name(action.get('action')))}</td>"
            f"<td>{html.escape(text_or_default(action.get('target'), '-'))}</td>"
            f"<td>{html.escape(text_or_default(action.get('detail'), '-'))}</td>"
            f"<td>{html.escape(text_or_default(action.get('error'), '-'))}</td>"
            "</tr>"
        )

    return (
        "<div class='table-scroll'>"
        "<table class='detail-table'>"
        "<thead><tr><th>步骤ID</th><th>动作</th><th>目标</th><th>详情</th><th>错误信息</th></tr></thead>"
        f"<tbody>{''.join(rows)}</tbody>"
        "</table>"
        "</div>"
    )


def build_html(
    run_id: str,
    run_dir: Path,
    tests: list[dict],
    summary: dict,
    network_note: str,
    generated_at: str,
    inline_images: bool,
    variant_label: str,
    delivery_note: str,
) -> str:
    sections: list[str] = []
    for test in tests:
        result = test["result"]
        debug_description = result.get("debug_description_relpath")
        debug_html = (
            "<span class='muted'>暂无</span>"
            if not debug_description
            else f"<a class='text-link' href='{html.escape(debug_description)}' target='_blank'>查看调试描述</a>"
        )

        sections.append(
            f"<section class='case-card' data-status='{html.escape(text_or_default(result.get('status'), 'unknown'))}'>"
            "<div class='case-top'>"
            "<div>"
            f"<p class='eyebrow'>测试用例</p><h2>{html.escape(translate_test_name(test['name']))}</h2>"
            f"<p class='case-subtitle'>开始于 {html.escape(format_timestamp(result.get('started_at_ms')))}，结束于 {html.escape(format_timestamp(result.get('ended_at_ms')))}</p>"
            "</div>"
            f"<div class='status-chip large {status_class(result.get('status'))}'>{html.escape(status_text(result.get('status')))}</div>"
            "</div>"
            "<div class='case-meta'>"
            f"<div class='meta-card'><span>总耗时</span><strong>{html.escape(format_duration(result.get('duration_ms')))}</strong></div>"
            f"<div class='meta-card'><span>失败步骤</span><strong>{html.escape(text_or_default(result.get('failure_step_id')))}</strong></div>"
            f"<div class='meta-card'><span>调试描述</span><strong>{debug_html}</strong></div>"
            f"<div class='meta-card'><span>步骤数量</span><strong>{len(test['steps'])}</strong></div>"
            "</div>"
            f"<div class='section-title-row'><h3>步骤截图与执行过程</h3><span class='muted'>{html.escape(delivery_note)}</span></div>"
            f"<div class='step-grid'>{build_step_cards(run_dir, test['steps'], inline_images)}</div>"
            "<div class='section-title-row'><h3>失败动作</h3></div>"
            f"{build_failed_actions_table(test['actions'])}"
            "</section>"
        )

    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>UI 自动化测试报告 {html.escape(variant_label)} {html.escape(run_id)}</title>
  <style>
    :root {{
      --bg: #f4f7f2;
      --card: rgba(255, 255, 255, 0.94);
      --line: #d9e3d1;
      --text: #1e2a1f;
      --muted: #5d6b5e;
      --accent: #1f7a59;
      --accent-soft: #dff4ea;
      --danger: #b33a3a;
      --danger-soft: #fde8e8;
      --shadow: 0 20px 50px rgba(36, 59, 41, 0.10);
    }}

    * {{
      box-sizing: border-box;
    }}

    body {{
      margin: 0;
      font-family: "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans SC", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(98, 187, 138, 0.18), transparent 28%),
        radial-gradient(circle at top right, rgba(255, 197, 102, 0.18), transparent 26%),
        linear-gradient(180deg, #eef7f0 0%, var(--bg) 36%, #edf1ec 100%);
      min-height: 100vh;
    }}

    .page {{
      width: min(1360px, calc(100vw - 32px));
      margin: 24px auto 48px;
    }}

    .hero {{
      position: relative;
      overflow: hidden;
      padding: 28px;
      border: 1px solid rgba(255, 255, 255, 0.55);
      border-radius: 28px;
      background: linear-gradient(135deg, rgba(28, 93, 66, 0.96), rgba(49, 119, 82, 0.88));
      color: #f6fff8;
      box-shadow: var(--shadow);
    }}

    .hero::after {{
      content: "";
      position: absolute;
      inset: auto -40px -60px auto;
      width: 240px;
      height: 240px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.08);
      filter: blur(2px);
    }}

    .eyebrow {{
      margin: 0 0 10px;
      font-size: 12px;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      opacity: 0.82;
    }}

    .hero h1 {{
      margin: 0;
      font-size: clamp(30px, 4vw, 52px);
      line-height: 1.05;
      font-weight: 800;
    }}

    .hero p {{
      margin: 12px 0 0;
      max-width: 860px;
      color: rgba(246, 255, 248, 0.88);
      line-height: 1.7;
    }}

    .hero-meta {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 14px;
      margin-top: 22px;
    }}

    .hero-pill {{
      padding: 14px 16px;
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.10);
      border: 1px solid rgba(255, 255, 255, 0.12);
      backdrop-filter: blur(10px);
    }}

    .hero-pill span {{
      display: block;
      font-size: 12px;
      opacity: 0.8;
      margin-bottom: 6px;
    }}

    .hero-pill strong {{
      font-size: 14px;
      word-break: break-all;
    }}

    .toolbar {{
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      align-items: center;
      justify-content: space-between;
      margin: 20px 0 18px;
    }}

    .toolbar-note {{
      color: var(--muted);
      font-size: 14px;
    }}

    .filters {{
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }}

    .filter-btn {{
      border: 0;
      border-radius: 999px;
      padding: 10px 16px;
      background: #ffffff;
      color: var(--text);
      box-shadow: 0 6px 18px rgba(36, 59, 41, 0.08);
      cursor: pointer;
      transition: transform 0.18s ease, background 0.18s ease, color 0.18s ease;
    }}

    .filter-btn:hover {{
      transform: translateY(-1px);
    }}

    .filter-btn.active {{
      background: var(--accent);
      color: #ffffff;
    }}

    .summary-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 14px;
      margin-bottom: 18px;
    }}

    .summary-card,
    .case-card,
    .panel {{
      background: var(--card);
      border: 1px solid rgba(217, 227, 209, 0.85);
      border-radius: 24px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(14px);
    }}

    .summary-card {{
      padding: 18px;
    }}

    .summary-card span {{
      display: block;
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 10px;
    }}

    .summary-card strong {{
      font-size: 32px;
      line-height: 1;
    }}

    .case-list {{
      display: grid;
      gap: 18px;
    }}

    .case-card {{
      padding: 22px;
    }}

    .case-card.is-hidden {{
      display: none;
    }}

    .case-top {{
      display: flex;
      justify-content: space-between;
      gap: 16px;
      align-items: flex-start;
    }}

    .case-top h2,
    .panel h2 {{
      margin: 4px 0 0;
      font-size: 26px;
      line-height: 1.2;
    }}

    .case-subtitle {{
      margin: 10px 0 0;
      color: var(--muted);
      line-height: 1.7;
    }}

    .status-chip {{
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 70px;
      padding: 6px 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.02em;
    }}

    .status-chip.large {{
      min-width: 92px;
      padding: 10px 16px;
      font-size: 15px;
    }}

    .status-chip.passed {{
      color: #176848;
      background: var(--accent-soft);
    }}

    .status-chip.failed {{
      color: #962a2a;
      background: var(--danger-soft);
    }}

    .status-chip.unknown {{
      color: #5e5535;
      background: #f8efd4;
    }}

    .case-meta {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
      margin: 18px 0 10px;
    }}

    .meta-card {{
      padding: 14px 16px;
      border-radius: 18px;
      background: #f7faf6;
      border: 1px solid var(--line);
    }}

    .meta-card span {{
      display: block;
      font-size: 12px;
      color: var(--muted);
      margin-bottom: 8px;
    }}

    .meta-card strong {{
      font-size: 16px;
      line-height: 1.5;
      word-break: break-word;
    }}

    .section-title-row {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-top: 22px;
      margin-bottom: 12px;
    }}

    .section-title-row h3 {{
      margin: 0;
      font-size: 18px;
    }}

    .muted {{
      color: var(--muted);
      font-size: 13px;
    }}

    .step-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 14px;
    }}

    .step-card {{
      padding: 16px;
      border-radius: 20px;
      background: linear-gradient(180deg, rgba(255, 255, 255, 0.96), rgba(248, 250, 247, 0.96));
      border: 1px solid var(--line);
    }}

    .step-header {{
      display: flex;
      justify-content: space-between;
      gap: 10px;
      align-items: center;
      margin-bottom: 12px;
    }}

    .step-id {{
      font-size: 13px;
      font-weight: 700;
      color: var(--accent);
      letter-spacing: 0.04em;
    }}

    .step-card h4 {{
      margin: 0 0 12px;
      font-size: 18px;
      line-height: 1.4;
    }}

    .meta-grid {{
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 12px;
    }}

    .meta-grid div {{
      padding: 10px 12px;
      border-radius: 14px;
      background: #f6faf5;
      border: 1px solid #e2eadc;
    }}

    .meta-grid span {{
      display: block;
      font-size: 12px;
      color: var(--muted);
      margin-bottom: 6px;
    }}

    .meta-grid strong {{
      font-size: 14px;
      word-break: break-word;
    }}

    .shot-wrapper {{
      margin-top: 12px;
    }}

    .shot-button {{
      width: 100%;
      border: 0;
      padding: 0;
      margin: 0;
      background: transparent;
      cursor: pointer;
      text-align: left;
    }}

    .shot-button img {{
      width: 100%;
      height: 200px;
      object-fit: cover;
      display: block;
      border-radius: 16px;
      border: 1px solid var(--line);
      box-shadow: 0 10px 30px rgba(36, 59, 41, 0.10);
    }}

    .shot-button span {{
      display: inline-block;
      margin-top: 10px;
      font-size: 13px;
      color: var(--accent);
      font-weight: 700;
    }}

    .shot-empty,
    .empty-state {{
      padding: 18px;
      border-radius: 16px;
      border: 1px dashed var(--line);
      background: #f7faf6;
      color: var(--muted);
      text-align: center;
    }}

    .error-box {{
      margin-top: 12px;
      padding: 12px 14px;
      border-radius: 16px;
      background: var(--danger-soft);
      color: #7e2727;
      border: 1px solid rgba(179, 58, 58, 0.14);
    }}

    .error-box strong {{
      display: block;
      margin-bottom: 6px;
    }}

    .error-box p {{
      margin: 0;
      line-height: 1.7;
      white-space: pre-wrap;
      word-break: break-word;
    }}

    .table-scroll {{
      overflow-x: auto;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: #fbfdfb;
    }}

    .detail-table {{
      width: 100%;
      border-collapse: collapse;
      min-width: 720px;
    }}

    .detail-table th,
    .detail-table td {{
      padding: 12px 14px;
      border-bottom: 1px solid #e7eee2;
      text-align: left;
      vertical-align: top;
    }}

    .detail-table th {{
      background: #eef7f0;
      font-size: 13px;
      color: #25452e;
    }}

    .detail-table td {{
      font-size: 14px;
      line-height: 1.6;
      word-break: break-word;
    }}

    .panel {{
      padding: 22px;
      margin-top: 18px;
    }}

    .panel p,
    .panel li {{
      line-height: 1.8;
      color: var(--text);
    }}

    .text-link {{
      color: var(--accent);
      text-decoration: none;
    }}

    .text-link:hover {{
      text-decoration: underline;
    }}

    .lightbox {{
      position: fixed;
      inset: 0;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 24px;
      background: rgba(13, 18, 14, 0.72);
      z-index: 999;
    }}

    .lightbox.open {{
      display: flex;
    }}

    .lightbox-dialog {{
      width: min(1200px, 96vw);
      max-height: 92vh;
      overflow: auto;
      background: rgba(17, 28, 19, 0.96);
      border-radius: 24px;
      padding: 20px;
      box-shadow: 0 30px 80px rgba(0, 0, 0, 0.32);
    }}

    .lightbox-head {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      color: #f7fff8;
      margin-bottom: 16px;
    }}

    .lightbox-head p {{
      margin: 0;
      color: rgba(247, 255, 248, 0.78);
    }}

    .lightbox-close {{
      border: 0;
      border-radius: 999px;
      padding: 10px 14px;
      cursor: pointer;
      background: rgba(255, 255, 255, 0.12);
      color: #ffffff;
    }}

    .lightbox img {{
      width: 100%;
      height: auto;
      display: block;
      border-radius: 18px;
      background: #0f1610;
    }}

    @media (max-width: 720px) {{
      .page {{
        width: min(100vw - 18px, 100%);
        margin: 12px auto 32px;
      }}

      .hero,
      .case-card,
      .panel {{
        padding: 18px;
        border-radius: 20px;
      }}

      .case-top {{
        flex-direction: column;
      }}

      .meta-grid {{
        grid-template-columns: 1fr;
      }}

      .toolbar {{
        align-items: flex-start;
      }}

      .shot-button img {{
        height: 180px;
      }}
    }}
  </style>
</head>
<body>
  <div class="page">
    <header class="hero">
      <p class="eyebrow">XCUITest / Flutter iOS</p>
      <h1>UI 自动化测试报告</h1>
      <p>当前版本：{html.escape(variant_label)}。本页基于本地测试侧采集到的步骤日志、动作日志、截图和结果文件生成，支持离线打开、筛选通过/失败用例，以及点击查看大图。</p>
      <div class="hero-meta">
        <div class="hero-pill"><span>运行ID</span><strong>{html.escape(run_id)}</strong></div>
        <div class="hero-pill"><span>生成时间</span><strong>{html.escape(generated_at)}</strong></div>
        <div class="hero-pill"><span>报告目录</span><strong>{html.escape(str(run_dir))}</strong></div>
        <div class="hero-pill"><span>交付说明</span><strong>{html.escape(delivery_note)}</strong></div>
      </div>
    </header>

    <section class="toolbar">
      <div class="filters">
        <button class="filter-btn active" type="button" data-filter="all">全部用例</button>
        <button class="filter-btn" type="button" data-filter="passed">仅看通过</button>
        <button class="filter-btn" type="button" data-filter="failed">仅看失败</button>
      </div>
      <div class="toolbar-note">当前共 {summary['tests']} 条用例。{html.escape(delivery_note)}</div>
    </section>

    <section class="summary-grid">
      <div class="summary-card"><span>用例总数</span><strong>{summary['tests']}</strong></div>
      <div class="summary-card"><span>通过用例</span><strong>{summary['passed']}</strong></div>
      <div class="summary-card"><span>失败用例</span><strong>{summary['failed']}</strong></div>
      <div class="summary-card"><span>截图数量</span><strong>{summary['screenshots']}</strong></div>
      <div class="summary-card"><span>JSONL 日志数量</span><strong>{summary['jsonl_logs']}</strong></div>
      <div class="summary-card"><span>失败步骤数</span><strong>{summary['failed_steps']}</strong></div>
      <div class="summary-card"><span>失败动作数</span><strong>{summary['failed_actions']}</strong></div>
    </section>

    <section class="case-list">
      {''.join(sections)}
    </section>

    <section class="panel">
      <h2>接口采集说明</h2>
      <p>{html.escape(network_note)}</p>
    </section>

    <section class="panel">
      <h2>备注</h2>
      <ul>
        <li>本报告优先使用测试侧本地证据文件，避免只依赖 <code>.xcresult</code> 附件。</li>
        <li>如果后续允许接入客户端网络层日志或外部代理抓包，这一页可以继续扩展接口请求、响应和异常区块。</li>
      </ul>
    </section>
  </div>

  <div class="lightbox" id="lightbox">
    <div class="lightbox-dialog">
      <div class="lightbox-head">
        <div>
          <strong>步骤截图预览</strong>
          <p id="lightbox-caption">-</p>
        </div>
        <button class="lightbox-close" id="lightbox-close" type="button">关闭</button>
      </div>
      <img id="lightbox-image" alt="步骤截图大图">
    </div>
  </div>

  <script>
    const filterButtons = Array.from(document.querySelectorAll('.filter-btn'));
    const caseCards = Array.from(document.querySelectorAll('.case-card'));
    filterButtons.forEach((button) => {{
      button.addEventListener('click', () => {{
        filterButtons.forEach((item) => item.classList.remove('active'));
        button.classList.add('active');
        const filter = button.dataset.filter;
        caseCards.forEach((card) => {{
          const status = card.dataset.status;
          const hidden = filter !== 'all' && status !== filter;
          card.classList.toggle('is-hidden', hidden);
        }});
      }});
    }});

    const lightbox = document.getElementById('lightbox');
    const lightboxImage = document.getElementById('lightbox-image');
    const lightboxCaption = document.getElementById('lightbox-caption');
    const closeLightbox = () => {{
      lightbox.classList.remove('open');
      lightboxImage.removeAttribute('src');
      lightboxCaption.textContent = '-';
    }};

    document.querySelectorAll('.shot-button').forEach((button) => {{
      button.addEventListener('click', () => {{
        lightboxImage.src = button.dataset.src || '';
        lightboxCaption.textContent = button.dataset.caption || '步骤截图';
        lightbox.classList.add('open');
      }});
    }});

    document.getElementById('lightbox-close').addEventListener('click', closeLightbox);
    lightbox.addEventListener('click', (event) => {{
      if (event.target === lightbox) {{
        closeLightbox();
      }}
    }});

    document.addEventListener('keydown', (event) => {{
      if (event.key === 'Escape') {{
        closeLightbox();
      }}
    }});
  </script>
</body>
</html>
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: render_report.py <run_dir>", file=sys.stderr)
        return 1

    run_dir = Path(sys.argv[1]).resolve()
    if not run_dir.is_dir():
        print(f"Run directory not found: {run_dir}", file=sys.stderr)
        return 1

    logs_dir = run_dir / "logs"
    result_files = sorted(logs_dir.glob("*_test_result.json"))
    tests: list[dict] = []
    failed_steps = 0
    failed_actions = 0

    for result_file in result_files:
        result = load_json_object(result_file) or {}
        stem = result_file.name.removesuffix("_test_result.json")
        steps = load_json_lines(logs_dir / f"{stem}_step_events.jsonl")
        actions = load_json_lines(logs_dir / f"{stem}_action_events.jsonl")
        failed_steps += sum(1 for step in steps if step.get("status") != "passed")
        failed_actions += sum(1 for action in actions if action.get("status") != "passed")
        tests.append(
            {
                "name": result.get("test_name", stem),
                "result": result,
                "steps": steps,
                "actions": actions,
            }
        )

    screenshot_count = sum(1 for _ in run_dir.rglob("*.png"))
    jsonl_count = sum(1 for _ in run_dir.rglob("*.jsonl"))
    summary = {
        "tests": len(tests),
        "passed": sum(1 for test in tests if test["result"].get("status") == "passed"),
        "failed": sum(1 for test in tests if test["result"].get("status") != "passed"),
        "screenshots": screenshot_count,
        "jsonl_logs": jsonl_count,
        "failed_steps": failed_steps,
        "failed_actions": failed_actions,
    }

    network_logs = list(run_dir.rglob("*network*.jsonl"))
    if network_logs:
        network_note = f"已检测到 {len(network_logs)} 个网络日志文件。后续可继续扩展渲染器，将请求、响应和异常信息直接展示到本页。"
    else:
        network_note = (
            "当前未发现应用侧网络日志文件。在“不能改业务源码”的约束下，请求与响应明细仍需要依赖外部代理抓包，"
            "或等待后续接入客户端网络层日志钩子。"
        )

    generated_at = dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
    run_id = run_dir.name
    markdown = build_markdown(run_id, run_dir, tests, summary, network_note, generated_at)
    single_file_html = build_html(
        run_id,
        run_dir,
        tests,
        summary,
        network_note,
        generated_at,
        inline_images=True,
        variant_label="单文件 HTML 版本",
        delivery_note="可单独转发此 HTML 文件，截图已内嵌。",
    )
    folder_bundle_html = build_html(
        run_id,
        run_dir,
        tests,
        summary,
        network_note,
        generated_at,
        inline_images=False,
        variant_label="文件夹版 HTML 版本",
        delivery_note="需要连同整个产物文件夹一起发送，页面通过相对路径读取截图。",
    )

    report_md = run_dir / "report.md"
    report_html = run_dir / "report.html"
    report_single_file_html = run_dir / "report_single_file.html"
    legacy_report_folder_bundle_html = run_dir / "report_folder_bundle.html"
    report_md.write_text(markdown, encoding="utf-8")
    report_html.write_text(folder_bundle_html, encoding="utf-8")
    report_single_file_html.write_text(single_file_html, encoding="utf-8")
    if legacy_report_folder_bundle_html.exists():
        legacy_report_folder_bundle_html.unlink()

    print(f"Report generated: {report_md}")
    print(f"Report generated: {report_html}")
    print(f"Report generated: {report_single_file_html}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
