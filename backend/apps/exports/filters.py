from dataclasses import dataclass
from datetime import date
from typing import Any


@dataclass
class ExportFilters:
    date_from: date | None = None
    date_to: date | None = None
    routine_id: int | None = None
    exercise_id: int | None = None
    include_workouts: bool = True
    include_body_measures: bool = True
    include_prs: bool = True

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> 'ExportFilters':
        return cls(
            date_from=data.get('date_from'),
            date_to=data.get('date_to'),
            routine_id=data.get('routine_id'),
            exercise_id=data.get('exercise_id'),
            include_workouts=data.get('include_workouts', True),
            include_body_measures=data.get('include_body_measures', True),
            include_prs=data.get('include_prs', True),
        )


@dataclass
class ExportPreview:
    workouts_count: int
    body_measures_count: int
    prs_count: int

    def to_dict(self) -> dict[str, int]:
        return {
            'workouts_count': self.workouts_count,
            'body_measures_count': self.body_measures_count,
            'prs_count': self.prs_count,
        }
