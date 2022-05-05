local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local internal = require "telescope.builtin.internal"
local conf = require("telescope.config").values
local entry_display = require "telescope.pickers.entry_display"
local builtin = require "telescope.builtin"

function gen_from_quickfix(opts)
  opts = opts or {}

  local displayer
  if opts.layout_strategy == 'horizontal' or  opts.layout_strategy == 'cursor' then
      displayer = entry_display.create {
          separator = "▏",
          items = {
              { width = 8 },
              { width = 0.618 },
              { remaining = true },
          },
      }
  else
      displayer = entry_display.create {
          separator = "▏",
          items = {
              { width = 8 },
              { width = 0.3 },
              { remaining = true },
          },
      }
  end

  local make_display = function(entry)
    local filename = utils.transform_path(opts, entry.filename)

    local line_info = { table.concat({ entry.lnum, entry.col }, ":"), "TelescopeResultsLineNr" }

    return displayer {
      line_info,
      filename,
      entry.text:gsub(".* | ", ""),
    }
  end

  return function(entry)
    local filename = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)

    return {
      valid = true,

      value = entry,
      ordinal = (not opts.ignore_filename and filename or "") .. " " .. entry.text,
      display = make_display,

      bufnr = entry.bufnr,
      filename = filename,
      lnum = entry.lnum,
      col = entry.col,
      text = entry.text,
      start = entry.start,
      finish = entry.finish,
    }
  end
end

internal.GscopeFind = function(opts)
  local locations = vim.fn.getqflist()

  if vim.tbl_isempty(locations) then
    return
  end

  if opts.layout_strategy == nil or opts.layout_strategy == '' then
      opts.layout_strategy = vim.g.gutentags_plus_layout_strategy or conf.layout_strategy
  end
  title = locations[1]['text']
  table.remove(locations, 1)
  if #locations == 1 then
      vim.cmd [[ cnext ]]
      return 0
  end

  pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table {
      results = locations,
      entry_maker = gen_from_quickfix(opts),
    },
    previewer = conf.qflist_previewer(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end

builtin.GscopeFind = internal.GscopeFind
