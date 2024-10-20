local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values

local jnv = require('jnv')
local state = require('jnv').state

local function list_bufs(bufnrs)
  local bufs = {}
  for _, bufnr in ipairs(bufnrs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      table.insert(bufs, {
        bufnr = bufnr,
        name = vim.api.nvim_buf_get_name(bufnr),
      })
    end
  end
  return bufs
end

local function search_win(bufnr)
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    local buf_in_window = vim.api.nvim_win_get_buf(win_id)
    if buf_in_window == bufnr then
      return win_id, true
    end
  end
  return -1, false
end

-- our picker function: colors
local function list_jnv(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      -- prompt_title = 'jnv',
      finder = finders.new_table({
        results = list_bufs(state.bufnrs),
        entry_maker = function(entry)
          return {
            value = entry,
            -- display = entry.name,
            display = 'buffer number: ' .. tostring(entry.bufnr),
            ordinal = entry.name .. tostring(entry.bufnr),
          }
        end,
      }),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          local lines = vim.api.nvim_buf_get_lines(entry.value.bufnr, 0, vim.o.lines, false)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, lines)
          vim.api.nvim_set_option_value('filetype', 'json', { buf = self.state.bufnr })
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- if window is already open, move there otherwise create a new window.
          local win_id, ok = search_win(selection.value.bufnr)
          if ok then
            vim.api.nvim_set_current_win(win_id)
            vim.api.nvim_win_set_cursor(win_id, { 1, 1 })
          else
            vim.api.nvim_open_win(selection.value.bufnr, true, jnv.build_win_opts())
          end
        end)
        return true
      end,
    })
    :find()
end

return require('telescope').register_extension({
  exports = {
    jnv = list_jnv,
  },
})
