'use strict'
import { DocumentLink, Location } from 'vscode-languageserver-types'
import { URI } from 'vscode-uri'
import languages from '../../languages'
import { ListContext, ListItem } from '../types'
import { isParentFolder } from '../../util/fs'
import { path } from '../../util/node'
import type { CancellationToken } from '../../util/protocol'
import workspace from '../../workspace'
import BasicList from '../basic'

export default class LinksList extends BasicList {
  public defaultAction = 'open'
  public description = 'links of current buffer'
  public name = 'links'

  constructor() {
    super()

    this.addAction('open', async item => {
      let { target } = item.data
      let uri = URI.parse(target)
      if (uri.scheme.startsWith('http')) {
        await workspace.nvim.call('coc#ui#open_url', target)
      } else {
        await workspace.jumpTo(target)
      }
    })

    this.addAction('jump', async item => {
      let { location } = item.data
      await workspace.jumpTo(location.uri, location.range.start)
    })
  }

  public async loadItems(context: ListContext, token: CancellationToken): Promise<ListItem[]> {
    let buf = await context.window.buffer
    let doc = workspace.getDocument(buf.id)
    if (!doc) return null
    let items: ListItem[] = []
    let links = await languages.getDocumentLinks(doc.textDocument, token)
    if (token.isCancellationRequested) return null
    if (links == null) throw new Error('Links provider not found.')
    let res: DocumentLink[] = []
    for (let link of links) {
      if (link.target) {
        items.push({
          label: formatUri(link.target),
          data: {
            target: link.target,
            location: Location.create(doc.uri, link.range)
          }
        })
      } else {
        link = await languages.resolveDocumentLink(link, token)
        if (link.target) {
          items.push({
            label: formatUri(link.target),
            data: {
              target: link.target,
              location: Location.create(doc.uri, link.range)
            }
          })
        }
        res.push(link)
      }
    }
    return items
  }
}

function formatUri(uri: string): string {
  if (!uri.startsWith('file:')) return uri
  let filepath = URI.parse(uri).fsPath
  return isParentFolder(workspace.cwd, filepath) ? path.relative(workspace.cwd, filepath) : filepath
}
