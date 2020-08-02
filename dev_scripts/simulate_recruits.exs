{opts, _, _} =
  OptionParser.parse(System.argv(),
    strict: [id: :integer, n: :integer, available: :boolean],
    aliases: [a: :available, n: :n]
  )

import Ecto.Query, only: [from: 2]

ids =
  from(req in Recake.Jobs.Request,
    where: req.job_id == ^opts[:id] and req.state == ^"pending",
    limit: ^opts[:n],
    order_by: fragment("random()"),
    select: req.id
  )
  |> Recake.Repo.all()

from(req in Recake.Jobs.Request,
  where: req.id in ^ids
)
|> Recake.Repo.update_all(
  set: [state: if(opts[:available], do: "available", else: "unavailable")]
)
