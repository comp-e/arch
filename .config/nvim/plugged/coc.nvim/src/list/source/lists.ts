'use strict'
import Mru from '../../model/mru'
import { IList, ListContext, ListItem } from '../types'
import { isVim } from '../../util/constants'
import BasicList from '../basic'
import { formatListItems, UnformattedListItem } from '../formatting'

const delay = isVim ? 50 : 0

export default class ListsList extends BasicList {
  public readonly name = 'lists'
  public readonly defaultAction = 'open'
  public readonly description = 'registered lists of coc.nvim'
  private mru: Mru = new Mru('lists')

  constructor(private readonly listMap: Map<string, IList>) {
    super()

    this.addAction('open', async item => {
      let { name } = item.data
      await this.mru.add(name)
      setTimeout(() => {
        this.nvim.command(`CocList ${name}`, true)
      }, delay)
    })
  }

  public async loadItems(_context: ListContext): Promise<ListItem[]> {
    let items: UnformattedListItem[] = []
    let mruList = await this.mru.load()
    for (let list of this.listMap.values()) {
      if (list.name == 'lists') continue
      items.push({
        label: [list.name, ...(list.description ? [list.description] : [])],
        data: {
          name: list.name,
          interactive: list.interactive,
          score: score(mruList, list.name)
        }
      })
    }
    items.sort((a, b) => b.data.score - a.data.score)
    return formatListItems(this.alignColumns, items)
  }

  public doHighlight(): void {
    let { nvim } = this
    nvim.pauseNotification()
    nvim.command('syntax match CocListsDesc /\\t.*$/ contained containedin=CocListsLine', true)
    nvim.command('highlight default link CocListsDesc Comment', true)
    nvim.resumeNotification(false, true)
  }
}

function score(list: string[], key: string): number {
  let idx = list.indexOf(key)
  return idx == -1 ? -1 : list.length - idx
}
