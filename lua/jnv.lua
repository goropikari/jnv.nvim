local M = {}

local default_config = {
  path = 'jnv', -- path to jnv
  args = {}, -- the arguments passed to the jnv
  window = {
    layout = 'vertical', -- 'vertical', 'horizontal', 'float', 'replace'
    width = 0.5, -- fractional width of parent
    height = 0.5, -- fractional height of parent
    -- Options below only apply to floating windows
    relative = 'editor', -- 'editor', 'win', 'cursor', 'mouse'
    border = 'single', -- 'none', single', 'double', 'rounded', 'solid', 'shadow'
    row = nil, -- row position of the window, default is centered
    col = nil, -- column position of the window, default is centered
    title = 'jnv', -- title of window
  },
}
local global_config = {}

local function get_visual_lines(opts)
  if vim.fn.mode() == 'n' then -- command から使う用
    return vim.fn.getline(opts.line1, opts.line2)
  else -- <leader> key を使った keymap 用
    local lines = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = vim.fn.mode() })
    -- https://github.com/neovim/neovim/discussions/26092
    vim.cmd([[ execute "normal! \<ESC>" ]])
    return lines
  end
end

local function get_visual_text(opts)
  local texts = get_visual_lines(opts or {})
  return vim.fn.join(texts, '')
end

local function get_buffer_text(bufnr)
  local texts = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return vim.fn.join(texts, '')
end

local function start_jnv(json_string)
  local temp_file = os.tmpname() .. '.json'
  local file, errmsg = io.open(temp_file, 'w')
  if file == nil then
    vim.notify(errmsg or ('failed to make a temporary file: ' .. temp_file), vim.log.levels.ERROR)
    return
  end
  file:write(json_string)
  file:close()

  local buf = vim.api.nvim_create_buf(false, true)

  local layout = global_config.window.layout
  local width = math.floor(vim.o.columns * global_config.window.width)
  local height = math.floor(vim.o.lines * global_config.window.height)
  local col = global_config.window.col or math.floor((vim.o.columns - width) / 2)
  local row = global_config.window.row or math.floor((vim.o.lines - height) / 2)
  local win_opts = {
    width = width,
    height = height,
    style = 'minimal',
  }
  if layout == 'float' then
    win_opts.relative = global_config.window.relative
    win_opts.col = col
    win_opts.row = row
    win_opts.title = global_config.window.title
    win_opts.border = global_config.window.border
    win_opts = vim.tbl_deep_extend('force', win_opts, {
      relative = global_config.window.relative,
      col = col,
      row = row,
      title = global_config.window.title,
      border = global_config.window.border,
    })
  elseif layout == 'vertical' then
    win_opts.split = 'left'
  elseif layout == 'horizontal' then
    win_opts.split = 'below'
  else
    win_opts.split = layout
  end

  local win_id = vim.api.nvim_open_win(buf, true, win_opts)

  local cmd = { global_config.path }
  vim.list_extend(cmd, global_config.args or {})
  table.insert(cmd, temp_file)

  vim.fn.termopen(vim.fn.join(cmd, ' '), {
    on_exit = function(_, exit_code, _)
      vim.notify('exit code ' .. tostring(exit_code))
      vim.api.nvim_win_close(win_id, true)
      os.remove(temp_file)
    end,
  })

  vim.cmd('startinsert')
end

function M.jnv_selection(opts)
  start_jnv(get_visual_text(opts))
end

function M.jnv_buffer(bufnr)
  if vim.bo.filetype ~= 'json' then
    vim.notify('jnv.nvim: support only json file', vim.log.levels.ERROR)
    return
  end
  start_jnv(get_buffer_text(bufnr))
end

function M.jnv_current_buffer()
  M.jnv_buffer(vim.api.nvim_get_current_buf())
end

function M.setup(opts)
  global_config = vim.tbl_deep_extend('force', default_config, opts or {})
end

return M
