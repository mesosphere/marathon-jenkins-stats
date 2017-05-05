#!/usr/bin/env amm

import ammonite.ops._

@main
def main(path: Path) = {
  val files = ls!(path) |? { _.name.split('.').last == "html" }

  val runningOnRegex = s"Running on (.+) in ".r
  val results = files.map { file =>
    val id = file.name.split('.').head.toInt
    val contents = read.lines(file).flatMap { line =>
      runningOnRegex.findFirstMatchIn(line)
    }.map(_.group(1)).headOption.getOrElse("")

    id -> contents
  }
  println("job-id\ninstance")
  results.sorted.foreach { case (id, instance) =>
    println(s"${id}\t${instance}")
  }
}

