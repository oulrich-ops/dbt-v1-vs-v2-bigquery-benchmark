"""Genere un projet dbt synthetique de N modeles pour mesurer le parsing.

Le temps de parsing depend du nombre de modeles, pas du volume de donnees :
ce projet ne lit aucune table (les modeles de base sont des SELECT de
constantes) et tout est materialise en vue.

Exemple :
    python scripts/gen_synthetic_project.py --models 5000
    cd synthetic_project
    dbt parse
"""

import argparse
import pathlib
import random
import shutil

PROJECT_YML = """name: synthetic_bench
version: "1.0.0"
profile: eth_bench

model-paths: ["models"]

models:
  synthetic_bench:
    +materialized: view
"""

BASE_SQL = """select
    {n} as id,
    {n} * 1.5 as amount,
    'group_{g}' as label
"""

JOIN_SQL = """with base as (

    select * from {{{{ ref('{first}') }}}}

){extra_ctes}

select
    base.id + {n} as id,
    base.amount{amount_expr} as amount,
    base.label
from base{joins}
"""


def model_name(index: int) -> str:
    return f"model_{index:05d}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--models", type=int, default=5000)
    parser.add_argument("--out", default="synthetic_project")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    root = pathlib.Path(__file__).resolve().parent.parent
    out = root / args.out
    if out.exists():
        shutil.rmtree(out)
    (out / "models").mkdir(parents=True)

    (out / "dbt_project.yml").write_text(PROJECT_YML, encoding="utf-8")
    shutil.copy(root / "profiles.yml", out / "profiles.yml")

    base_count = max(1, args.models // 10)
    group_size = 100

    for start in range(0, args.models, group_size):
        folder = out / "models" / f"group_{start // group_size:03d}"
        folder.mkdir()
        yml = ["version: 2", "", "models:"]

        for n in range(start, min(start + group_size, args.models)):
            name = model_name(n)
            if n < base_count:
                sql = BASE_SQL.format(n=n, g=n % 7)
            else:
                # 1 a 3 parents choisis parmi les 500 modeles precedents
                window = range(max(0, n - 500), n)
                parents = rng.sample(window, k=min(len(window), rng.randint(1, 3)))
                first, others = parents[0], parents[1:]
                extra_ctes = "".join(
                    f",\n\np{i} as (\n\n    select * from {{{{ ref('{model_name(p)}') }}}}\n\n)"
                    for i, p in enumerate(others)
                )
                joins = "".join(
                    f"\nleft join p{i} on base.id = p{i}.id" for i in range(len(others))
                )
                amount_expr = "".join(
                    f" + coalesce(p{i}.amount, 0)" for i in range(len(others))
                )
                sql = JOIN_SQL.format(
                    first=model_name(first),
                    n=n,
                    extra_ctes=extra_ctes,
                    joins=joins,
                    amount_expr=amount_expr,
                )
            (folder / f"{name}.sql").write_text(sql, encoding="utf-8", newline="\n")

            yml += [
                f"  - name: {name}",
                f"    description: Modele synthetique numero {n}.",
                "    columns:",
                "      - name: id",
                "        description: Identifiant technique.",
                "        data_tests: [not_null]",
                "      - name: amount",
                "        description: Montant calcule.",
                "      - name: label",
                "        description: Libelle de groupe.",
            ]

        (folder / "_models.yml").write_text("\n".join(yml) + "\n", encoding="utf-8", newline="\n")

    print(f"{args.models} modeles generes dans {out}")


if __name__ == "__main__":
    main()
