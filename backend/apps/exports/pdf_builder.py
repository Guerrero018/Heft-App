from __future__ import annotations

from datetime import datetime, timezone

from fpdf import FPDF

from apps.workouts.models import WorkoutSession

_DARK = (18, 18, 18)
_PRIMARY = (226, 241, 99)
_CARD = (30, 30, 30)
_TEXT = (255, 255, 255)
_HINT = (136, 136, 136)


class HeftExportPDF(FPDF):
    def __init__(self, username: str, filters_summary: str):
        super().__init__()
        self.username = username
        self.filters_summary = filters_summary
        self.set_auto_page_break(auto=True, margin=18)
        self.set_margins(14, 32, 14)

    def header(self) -> None:
        self.set_fill_color(*_DARK)
        self.rect(0, 0, self.w, 24, style='F')
        self.set_y(6)
        self.set_font('Helvetica', 'B', 18)
        self.set_text_color(*_PRIMARY)
        self.cell(40, 12, 'HEFT')
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*_HINT)
        self.cell(0, 12, 'Exportacion de datos', align='R', ln=True)
        self.ln(6)

    def footer(self) -> None:
        self.set_y(-14)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(*_HINT)
        self.cell(
            0,
            8,
            f'Generado para {self.username}  |  Pagina {self.page_no()}/{{nb}}',
            align='C',
        )

    def cover_block(self) -> None:
        self.add_page()
        self.set_fill_color(*_CARD)
        self.rect(14, self.get_y(), self.w - 28, 42, style='F')
        self.set_xy(20, self.get_y() + 8)
        self.set_font('Helvetica', 'B', 20)
        self.set_text_color(*_PRIMARY)
        self.cell(0, 10, 'Resumen de exportacion', ln=True)
        self.set_x(20)
        self.set_font('Helvetica', '', 11)
        self.set_text_color(*_TEXT)
        self.cell(0, 8, f'Usuario: {self.username}', ln=True)
        self.set_x(20)
        self.set_text_color(*_HINT)
        self.cell(0, 8, f'Filtros: {self.filters_summary}', ln=True)
        self.set_x(20)
        generated = datetime.now(timezone.utc).strftime('%d/%m/%Y %H:%M UTC')
        self.cell(0, 8, f'Generado: {generated}', ln=True)
        self.ln(12)

    def section_title(self, title: str, count: int) -> None:
        self.ln(4)
        self.set_fill_color(*_DARK)
        self.set_text_color(*_PRIMARY)
        self.set_font('Helvetica', 'B', 13)
        self.cell(0, 10, f'{title} ({count})', fill=True, ln=True)
        self.ln(2)

    def draw_table(self, headers: list[str], rows: list[list[str]], col_widths: list[float]) -> None:
        self._print_table_header(headers, col_widths)
        fill = False
        for row in rows:
            if self.get_y() > self.h - 20:
                self.add_page()
                self._print_table_header(headers, col_widths)
            if fill:
                self.set_fill_color(*_CARD)
                self.set_text_color(*_TEXT)
            else:
                self.set_fill_color(245, 245, 245)
                self.set_text_color(40, 40, 40)
            self.set_font('Helvetica', '', 8)
            for index, cell in enumerate(row):
                self.cell(col_widths[index], 6, str(cell)[:28], fill=True)
            self.ln()
            fill = not fill
        self.ln(4)

    def _print_table_header(self, headers: list[str], col_widths: list[float]) -> None:
        self.set_font('Helvetica', 'B', 8)
        self.set_fill_color(*_DARK)
        self.set_text_color(*_PRIMARY)
        for index, header in enumerate(headers):
            self.cell(col_widths[index], 7, header, fill=True)
        self.ln()

    def empty_notice(self, message: str) -> None:
        self.set_font('Helvetica', 'I', 10)
        self.set_text_color(*_HINT)
        self.cell(0, 8, message, ln=True)


def _duration_minutes(session: WorkoutSession) -> str:
    if session.start_time and session.end_time:
        delta = session.end_time - session.start_time
        return str(int(delta.total_seconds() // 60))
    return '-'


def build_pdf_export(data: dict) -> tuple[bytes, str]:
    pdf = HeftExportPDF(data['generated_for'], data['filters_summary'])
    pdf.alias_nb_pages()
    pdf.cover_block()

    if data['workouts']:
        pdf.section_title('Historial de entrenamientos', len(data['workouts']))
        rows: list[list[str]] = []
        for session in data['workouts']:
            routine_name = session.routine.name if session.routine else '-'
            for workout_set in session.sets.all():
                rows.append(
                    [
                        session.date.strftime('%d/%m/%Y'),
                        (session.name or 'Entrenamiento')[:18],
                        routine_name[:14],
                        workout_set.exercise.name[:16],
                        f'{workout_set.weight:.1f}',
                        str(workout_set.reps),
                        _duration_minutes(session),
                    ],
                )
        pdf.draw_table(
            ['Fecha', 'Sesion', 'Rutina', 'Ejercicio', 'Kg', 'Reps', 'Min'],
            rows,
            [22, 28, 26, 30, 14, 14, 14],
        )
    elif data.get('include_workouts_flag'):
        pdf.section_title('Historial de entrenamientos', 0)
        pdf.empty_notice('No hay entrenamientos con los filtros seleccionados.')

    if data['body_measures']:
        pdf.section_title('Medidas corporales', len(data['body_measures']))
        rows = [
            [
                measure.date.strftime('%d/%m/%Y'),
                f'{measure.weight:.1f}',
                f'{measure.waist_cm:.0f}' if measure.waist_cm else '-',
                f'{measure.chest_cm:.0f}' if measure.chest_cm else '-',
                (measure.notes or '-')[:40],
            ]
            for measure in data['body_measures']
        ]
        pdf.draw_table(
            ['Fecha', 'Peso kg', 'Cintura', 'Pecho', 'Notas'],
            rows,
            [24, 22, 22, 22, 80],
        )

    if data['prs']:
        pdf.section_title('Records personales', len(data['prs']))
        rows = [
            [
                row['exercise_name'][:22],
                row['muscle_group'][:14],
                f"{row['max_weight_kg']:.1f}",
                str(row['reps']),
                row['date'],
            ]
            for row in data['prs']
        ]
        pdf.draw_table(
            ['Ejercicio', 'Musculo', 'Max kg', 'Reps', 'Fecha'],
            rows,
            [48, 32, 22, 18, 28],
        )

    if not data['workouts'] and not data['body_measures'] and not data['prs']:
        pdf.empty_notice('No hay datos para exportar con los filtros seleccionados.')

    stamp = datetime.now(timezone.utc).strftime('%Y%m%d')
    filename = f'heft_export_{stamp}.pdf'
    return _pdf_bytes(pdf), filename


def _pdf_bytes(pdf: FPDF) -> bytes:
    try:
        raw = pdf.output(dest='S')
    except TypeError:
        raw = pdf.output()

    if isinstance(raw, (bytes, bytearray)):
        return bytes(raw)
    if isinstance(raw, str):
        return raw.encode('latin-1')
    return bytes(raw)
