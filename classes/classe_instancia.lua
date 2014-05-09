local AceLocale = LibStub ("AceLocale-3.0")
local Loc = AceLocale:GetLocale ( "Details" )
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local _type= type  --> lua local
local _ipairs = ipairs --> lua local
local _pairs = pairs --> lua local
local _math_floor = math.floor --> lua local
local _math_abs = math.abs --> lua local
local _table_remove = table.remove --> lua local
local _getmetatable = getmetatable --> lua local
local _setmetatable = setmetatable --> lua local
local _string_len = string.len --> lua local
local _unpack = unpack --> lua local
local _cstr = string.format --> lua local
local _SendChatMessage = SendChatMessage --> wow api locals
local _GetChannelName = GetChannelName --> wow api locals
local _UnitExists = UnitExists --> wow api locals
local _UnitName = UnitName --> wow api locals
local _UnitIsPlayer = UnitIsPlayer --> wow api locals

local _detalhes = 		_G._detalhes
local gump = 			_detalhes.gump

local historico = 			_detalhes.historico

local modo_raid = _detalhes._detalhes_props["MODO_RAID"]
local modo_alone = _detalhes._detalhes_props["MODO_ALONE"]
local modo_grupo = _detalhes._detalhes_props["MODO_GROUP"]
local modo_all = _detalhes._detalhes_props["MODO_ALL"]

local _

local atributos = _detalhes.atributos
local sub_atributos = _detalhes.sub_atributos
local segmentos = _detalhes.segmentos

--> STARTUP reativa as instancias e regenera as tabelas das mesmas
	function _detalhes:RestartInstances()
		return _detalhes:ReativarInstancias()
	end
	
	function _detalhes:ReativarInstancias()
		_detalhes.opened_windows = 0
		for index = #_detalhes.tabela_instancias, 1, -1 do 
			local instancia = _detalhes.tabela_instancias [index]
			if (not _getmetatable (instancia)) then
				_setmetatable (_detalhes.tabela_instancias[index], _detalhes)
			end
			if (instancia:IsAtiva()) then --> s� reabre se ela estiver ativa
				instancia:RestauraJanela (index)
				if (not _detalhes.initializing) then
					_detalhes:SendEvent ("DETAILS_INSTANCE_OPEN", nil, instancia)
				end
			else
				instancia.iniciada = false
			end
		end
		--print ("Abertas: " .. _detalhes.opened_windows)
	end
	
------------------------------------------------------------------------------------------------------------------------

--> API: call a function to all enabled instances
function _detalhes:InstanceCall (funcao, ...)
	for index, instance in _ipairs (_detalhes.tabela_instancias) do
		if (instance:IsAtiva()) then --> only enabled
			funcao (instance, ...)
		end
	end
end

--> chama a fun��o para ser executada em todas as inst�ncias	(internal)
function _detalhes:InstanciaCallFunction (funcao, ...)
	for index, instancia in _ipairs (_detalhes.tabela_instancias) do
		if (instancia:IsAtiva()) then --> s� reabre se ela estiver ativa
			funcao (_, instancia, ...) 
		end
	end
end

--> chama a fun��o para ser executada em todas as inst�ncias	(internal)
function _detalhes:InstanciaCallFunctionOffline (funcao, ...)
	for index, instancia in _ipairs (_detalhes.tabela_instancias) do
		funcao (_, instancia, ...)
	end
end

function _detalhes:GetLowerInstanceNumber()
	local lower = 999
	for index, instancia in _ipairs (_detalhes.tabela_instancias) do
		if (instancia.ativa and instancia.baseframe) then
			if (instancia.meu_id < lower) then
				lower = instancia.meu_id
			end
		end
	end
	if (lower == 999) then
		_detalhes.lower_instance = 0
		return nil
	else
		_detalhes.lower_instance = lower
		return lower
	end
end

function _detalhes:IsLowerInstance()
	local lower = _detalhes:GetLowerInstanceNumber()
	if (lower) then
		return lower == self.meu_id
	end
	return false
end

function _detalhes:IsInteracting()
	return self.is_interacting
end

function _detalhes:GetMode()
	return self.modo
end

function _detalhes:GetInstance (id)
	return _detalhes.tabela_instancias [id]
end

function _detalhes:GetId()
	return self.meu_id
end
function _detalhes:GetInstanceId()
	return self.meu_id
end

function _detalhes:GetSegment()
	return self.segmento
end

function _detalhes:GetSoloMode()
	return _detalhes.tabela_instancias [_detalhes.solo]
end
function _detalhes:GetRaidMode()
	return _detalhes.tabela_instancias [_detalhes.raid]
end

function _detalhes:IsSoloMode()
	if (not _detalhes.solo) then
		return false
	else
		return _detalhes.solo == self:GetInstanceId()
	end
end

function _detalhes:IsRaidMode()
	if (not _detalhes.raid) then
		return false
	else
		return _detalhes.raid == self:GetInstanceId()
	end
end

function _detalhes:IsNormalMode()
	if (self:GetInstanceId() == 2 or self:GetInstanceId() == 3) then
		return true
	else
		return false
	end
end

------------------------------------------------------------------------------------------------------------------------

--> retorna se a inst�ncia esta ou n�o ativa
function _detalhes:IsAtiva()
	return self.ativa
end
--> english alias
function _detalhes:IsEnabled()
	return self.ativa
end


------------------------------------------------------------------------------------------------------------------------

	function _detalhes:ShutDown()
		return self:DesativarInstancia()
	end

--> desativando a inst�ncia ela fica em stand by e apenas hida a janela
	function _detalhes:DesativarInstancia()
	
		local lower = _detalhes:GetLowerInstanceNumber()

		self.ativa = false
		_detalhes:GetLowerInstanceNumber()
		
		if (lower == self.meu_id) then
			--> os icones dos plugins estao hostiados nessa instancia.
			_detalhes.ToolBar:ReorganizeIcons (true) --n�o precisa recarregar toda a skin
		end
		
		if (_detalhes.switch.current_instancia and _detalhes.switch.current_instancia == self) then
			_detalhes.switch:CloseMe()
		end
		
		_detalhes.opened_windows = _detalhes.opened_windows-1
		self:ResetaGump()
		
		--gump:Fade (self.baseframe.cabecalho.atributo_icon, _unpack (_detalhes.windows_fade_in))
		gump:Fade (self.baseframe.cabecalho.ball, _unpack (_detalhes.windows_fade_in))
		gump:Fade (self.baseframe, _unpack (_detalhes.windows_fade_in))
		gump:Fade (self.rowframe, _unpack (_detalhes.windows_fade_in))
		
		self:Desagrupar (-1)
		
		if (self.modo == modo_raid) then
			_detalhes.RaidTables:switch()
			_detalhes.raid = nil
			
		elseif (self.modo == modo_alone) then
			_detalhes.SoloTables:switch()
			self.atualizando = false
			_detalhes.solo = nil
		end
		
		--print ("Abertas: " .. _detalhes.opened_windows)
		if (not _detalhes.initializing) then
			_detalhes:SendEvent ("DETAILS_INSTANCE_CLOSE", nil, self)
		end
		
	end
------------------------------------------------------------------------------------------------------------------------

	function _detalhes:InstanciaFadeBarras (instancia, segmento)
		local _fadeType, _fadeSpeed = _unpack (_detalhes.row_fade_in)
		if (segmento) then
			if (instancia.segmento == segmento) then
				return gump:Fade (instancia, _fadeType, _fadeSpeed, "barras")
			end
		else
			return gump:Fade (instancia, _fadeType, _fadeSpeed, "barras")
		end
	end

	-- reabre todas as instancias
	function _detalhes:ReabrirTodasInstancias (temp)
		for index = #_detalhes.tabela_instancias, 1, -1 do 
			local instancia = _detalhes:GetInstance (index)
			instancia:AtivarInstancia (temp)
		end
	end
	
	function _detalhes:LockInstance (flag)
		
		if (type (flag) == "boolean") then
			self.isLocked = not flag
		end
	
		if (self.isLocked) then
			self.isLocked = false
			if (self.baseframe) then
				self.baseframe.isLocked = false
				self.baseframe.lock_button.label:SetText (Loc ["STRING_LOCK_WINDOW"])
				self.baseframe.lock_button:SetWidth (self.baseframe.lock_button.label:GetStringWidth()+2)
				self.baseframe.resize_direita:SetAlpha (0)
				self.baseframe.resize_esquerda:SetAlpha (0)
				self.baseframe.lock_button:ClearAllPoints()
				self.baseframe.lock_button:SetPoint ("right", self.baseframe.resize_direita, "left", -1, 1.5)
			end
		else
			self.isLocked = true
			if (self.baseframe) then
				self.baseframe.isLocked = true
				self.baseframe.lock_button.label:SetText (Loc ["STRING_UNLOCK_WINDOW"])
				self.baseframe.lock_button:SetWidth (self.baseframe.lock_button.label:GetStringWidth()+2)
				self.baseframe.lock_button:ClearAllPoints()
				self.baseframe.lock_button:SetPoint ("bottomright", self.baseframe, "bottomright", -3, 0)
				self.baseframe.resize_direita:SetAlpha (1)
				self.baseframe.resize_esquerda:SetAlpha (1)
			end
		end
	end
	
	function _detalhes:TravasInstancias()
		for index, instancia in ipairs (_detalhes.tabela_instancias) do 
			instancia:LockInstance (true)
		end
	end
	
	function _detalhes:DestravarInstancias()
		for index, instancia in ipairs (_detalhes.tabela_instancias) do 
			instancia:LockInstance (false)
		end
	end

--> oposto do desativar, ela apenas volta a mostrar a janela
	function _detalhes:AtivarInstancia (temp)
	
		self.ativa = true
		local lower = _detalhes:GetLowerInstanceNumber()
		
		if (lower == self.meu_id) then
			--> os icones dos plugins precisam ser hostiados nessa instancia.
			_detalhes.ToolBar:ReorganizeIcons (true) --> n�o precisa recarregar toda a skin
		end
		
		if (not self.iniciada) then
			self:RestauraJanela (self.meu_id)
		else
			_detalhes.opened_windows = _detalhes.opened_windows+1
		end

		_detalhes:TrocaTabela (self, nil, nil, nil, true)
		
		--gump:Fade (self.baseframe.cabecalho.atributo_icon, _unpack (_detalhes.windows_fade_out))
		--gump:Fade (self.baseframe.cabecalho.ball, _unpack (_detalhes.windows_fade_out))
		--gump:Fade (self.baseframe, _unpack (_detalhes.windows_fade_out))

		if (self.hide_icon) then
			gump:Fade (self.baseframe.cabecalho.atributo_icon, 1)
		else
			gump:Fade (self.baseframe.cabecalho.atributo_icon, 0)
		end
		
		gump:Fade (self.baseframe.cabecalho.ball, 0)
		gump:Fade (self.baseframe, 0)
		gump:Fade (self.rowframe, 0)
		
		self:SetMenuAlpha()
		
		self.baseframe.cabecalho.fechar:Enable()
		
		self:ChangeIcon()

		if (not temp) then
			if (self.modo == modo_raid) then
				_detalhes:RaidMode (true, self)
				
			elseif (self.modo == modo_alone) then
				self:SoloMode (true)
			end
		end
		
		self:SetCombatAlpha (nil, nil, true)
		
		--if (self.hide_out_of_combat and not UnitAffectingCombat ("player")) then
		--	self:SetWindowAlphaForCombat (true, true)
		--end
		
		if (not temp and not _detalhes.initializing) then
			_detalhes:SendEvent ("DETAILS_INSTANCE_OPEN", nil, self)
		end
	end
------------------------------------------------------------------------------------------------------------------------

--> apaga de vez um inst�ncia
	function _detalhes:ApagarInstancia (ID)
		return _table_remove (_detalhes.tabela_instancias, ID)
	end
------------------------------------------------------------------------------------------------------------------------

--> retorna quantas inst�ncia h� no momento
	function _detalhes:QuantasInstancias()
		return #_detalhes.tabela_instancias
	end
------------------------------------------------------------------------------------------------------------------------

	function _detalhes:DeleteInstance (id)
	
		local instance = _detalhes:GetInstance (id)
		
		if (not instance) then
			return false
		end
		
		--verifica se esta aberta
		if (instance:IsEnabled()) then
			instance:ShutDown()
		end

		--fixas os snaps nas janelas superiores
		for i = id+1, #_detalhes.tabela_instancias do
			local this_instance = _detalhes:GetInstance (i)
			
			--down the id
			this_instance.meu_id = i-1
			
			--fix the snaps
			for index, id in _pairs (this_instance.snap) do
				if (id == i+1) then --snap na proxima instancia
					this_instance.snap [index] = i
				elseif (id == i-1) then --snap na instancia anterior
					this_instance.snap [index] = i-2
				end
			end
		end
		
		--remover do container tabela_instancias
		tremove (_detalhes.tabela_instancias, id)
		
	end


------------------------------------------------------------------------------------------------------------------------
--> cria uma nova inst�ncia e a joga para o container de inst�ncias

	function _detalhes:CreateInstance (id)
		return _detalhes:CriarInstancia (_, id)
	end

	function _detalhes:CriarInstancia (_, id)

		if (id and _type (id) == "boolean") then
			
			if (#_detalhes.tabela_instancias >= _detalhes.instances_amount) then
				_detalhes:Msg (Loc ["STRING_INSTANCE_LIMIT"])
				return false
			end
			
			local new_instance = _detalhes:NovaInstancia (#_detalhes.tabela_instancias+1)
			
			return new_instance
			
		elseif (id) then
			local instancia = _detalhes.tabela_instancias [id]
			if (instancia and not instancia:IsAtiva()) then
				instancia:AtivarInstancia()
				return
			end
		end
	
		--> antes de criar uma nova, ver se n�o h� alguma para reativar
		for index, instancia in _ipairs (_detalhes.tabela_instancias) do
			if (not instancia:IsAtiva()) then
				instancia:AtivarInstancia()
				return
			end
		end
		
		if (#_detalhes.tabela_instancias >= _detalhes.instances_amount) then
			return _detalhes:Msg (Loc ["STRING_INSTANCE_LIMIT"])
		end
		
		local new_instance = _detalhes:NovaInstancia (#_detalhes.tabela_instancias+1)
		
		if (not _detalhes.initializing) then
			_detalhes:SendEvent ("DETAILS_INSTANCE_OPEN", nil, new_instance)
		end
		
		_detalhes:GetLowerInstanceNumber()
		
		return new_instance
	end
------------------------------------------------------------------------------------------------------------------------

--> self � a inst�ncia que esta sendo movida.. instancia � a que esta parada
function _detalhes:EstaAgrupada (esta_instancia, lado) --> lado //// 1 = encostou na esquerda // 2 = escostou emaixo // 3 = encostou na direita // 4 = encostou em cima
	--local meu_snap = self.snap --> pegou a tabela com {side, side, side, side}
	
	if (esta_instancia.snap [lado]) then
		return true --> ha possui uma janela grudapa neste lado
	elseif (lado == 1) then
		if (self.snap [3]) then
			return true
		end
	elseif (lado == 2) then
		if (self.snap [4]) then
			return true
		end
	elseif (lado == 3) then
		if (self.snap [1]) then
			return true
		end
	elseif (lado == 4) then
		if (self.snap [2]) then
			return true
		end
	end

	return false --> do contr�rio retorna false
end

function _detalhes:BaseFrameSnap()

	for meu_id, instancia in _ipairs (_detalhes.tabela_instancias) do
		if (instancia:IsAtiva()) then
			instancia.baseframe:ClearAllPoints()
		end
	end
	
	local my_baseframe = self.baseframe
	for lado, snap_to in _pairs (self.snap) do
		--print ("DEBUG instancia " .. snap_to .. " lado "..lado)
		local instancia_alvo = _detalhes.tabela_instancias [snap_to]

		if (lado == 1) then --> a esquerda
			instancia_alvo.baseframe:SetPoint ("TOPRIGHT", my_baseframe, "TOPLEFT")
			
		elseif (lado == 2) then --> em baixo
			local statusbar_y_mod = 0
			if (not self.show_statusbar) then
				statusbar_y_mod = 14
			end
			instancia_alvo.baseframe:SetPoint ("TOPLEFT", my_baseframe, "BOTTOMLEFT", 0, -34 + statusbar_y_mod)
			
		elseif (lado == 3) then --> a direita
			instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", my_baseframe, "BOTTOMRIGHT")
			
		elseif (lado == 4) then --> em cima
			local statusbar_y_mod = 0
			if (not instancia_alvo.show_statusbar) then
				statusbar_y_mod = -14
			end
			instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", my_baseframe, "TOPLEFT", 0, 34 + statusbar_y_mod)

		end
	end

	--[
	--> aqui precisa de um efeito reverso
	local reverso = self.meu_id - 2 --> se existir 
	if (reverso > 0) then --> se tiver uma inst�ncia l� tr�s
		--> aqui faz o efeito reverso:
		local inicio_retro = self.meu_id - 1
		for meu_id = inicio_retro, 1, -1 do
			local instancia = _detalhes.tabela_instancias [meu_id]
			for lado, snap_to in _pairs (instancia.snap) do
				if (snap_to < instancia.meu_id and snap_to ~= self.meu_id) then --> se o lado que esta grudado for menor que o meu id... EX instnacia #2 grudada na #1
				
					--> ent�o tenho que pegar a inst�ncia do snap

					local instancia_alvo = _detalhes.tabela_instancias [snap_to]
					local lado_reverso
					if (lado == 1) then
						lado_reverso = 3
					elseif (lado == 2) then
						lado_reverso = 4
					elseif (lado == 3) then
						lado_reverso = 1
					elseif (lado == 4) then
						lado_reverso = 2
					end

					--> fazer os setpoints
					if (lado_reverso == 1) then --> a esquerda
						instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", instancia.baseframe, "BOTTOMRIGHT")
						
					elseif (lado_reverso == 2) then --> em baixo
					
						local statusbar_y_mod = 0
						if (not instancia_alvo.show_statusbar) then
							statusbar_y_mod = -14
						end
						
						instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", instancia.baseframe, "TOPLEFT", 0, 34 + statusbar_y_mod) -- + (statusbar_y_mod*-1)
						
					elseif (lado_reverso == 3) then --> a direita
						instancia_alvo.baseframe:SetPoint ("TOPRIGHT", instancia.baseframe, "TOPLEFT")
						
					elseif (lado_reverso == 4) then --> em cima
					
						local statusbar_y_mod = 0
						if (not instancia.show_statusbar) then
							statusbar_y_mod = 14
						end
					
						instancia_alvo.baseframe:SetPoint ("TOPLEFT", instancia.baseframe, "BOTTOMLEFT", 0, -34 + statusbar_y_mod)
						
					end
				end
			end
		end
	end
	--]]
	
	for meu_id, instancia in _ipairs (_detalhes.tabela_instancias) do
		if (meu_id > self.meu_id) then
			for lado, snap_to in _pairs (instancia.snap) do
				if (snap_to > instancia.meu_id and snap_to ~= self.meu_id) then
					local instancia_alvo = _detalhes.tabela_instancias [snap_to]
					
					if (lado == 1) then --> a esquerda
						instancia_alvo.baseframe:SetPoint ("TOPRIGHT", instancia.baseframe, "TOPLEFT")
						
					elseif (lado == 2) then --> em baixo
						local statusbar_y_mod = 0
						if (not instancia.show_statusbar) then
							statusbar_y_mod = 14
						end
						instancia_alvo.baseframe:SetPoint ("TOPLEFT", instancia.baseframe, "BOTTOMLEFT", 0, -34 + statusbar_y_mod)
						
					elseif (lado == 3) then --> a direita
						instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", instancia.baseframe, "BOTTOMRIGHT")
						
					elseif (lado == 4) then --> em cima
					
						local statusbar_y_mod = 0
						if (not instancia_alvo.show_statusbar) then
							statusbar_y_mod = -14
						end
					
						instancia_alvo.baseframe:SetPoint ("BOTTOMLEFT", instancia.baseframe, "TOPLEFT", 0, 34 + statusbar_y_mod)
						
					end
				end
			end
		end
	end
end

function _detalhes:agrupar_janelas (lados)

	local instancia = self
	
	for lado, esta_instancia in _pairs (lados) do
		if (esta_instancia) then
			instancia.baseframe:ClearAllPoints()
			esta_instancia = _detalhes.tabela_instancias [esta_instancia]
			
			if (lado == 3) then --> direita
				--> mover frame
				instancia.baseframe:SetPoint ("TOPRIGHT", esta_instancia.baseframe, "TOPLEFT")
				instancia.baseframe:SetPoint ("RIGHT", esta_instancia.baseframe, "LEFT")
				instancia.baseframe:SetPoint ("BOTTOMRIGHT", esta_instancia.baseframe, "BOTTOMLEFT")
				
				local _, height = esta_instancia:GetSize()
				instancia:SetSize (nil, height)
				
				--> salva o snap
				self.snap [3] = esta_instancia.meu_id
				esta_instancia.snap [1] = self.meu_id
				
			elseif (lado == 4) then --> cima
				--> mover frame
				
				local statusbar_y_mod = 0
				if (not esta_instancia.show_statusbar) then
					statusbar_y_mod = 14
				end
				
				instancia.baseframe:SetPoint ("TOPLEFT", esta_instancia.baseframe, "BOTTOMLEFT", 0, -34 + statusbar_y_mod)
				instancia.baseframe:SetPoint ("TOP", esta_instancia.baseframe, "BOTTOM", 0, -34 + statusbar_y_mod)
				instancia.baseframe:SetPoint ("TOPRIGHT", esta_instancia.baseframe, "BOTTOMRIGHT", 0, -34 + statusbar_y_mod)
				
				local _, height = esta_instancia:GetSize()
				instancia:SetSize (nil, height)
				
				--> salva o snap
				self.snap [4] = esta_instancia.meu_id
				esta_instancia.snap [2] = self.meu_id
				
				--esta_instancia.baseframe.rodape.StatusBarLeftAnchor:SetPoint ("left", esta_instancia.baseframe.rodape.top_bg, "left", 25, 58)
				--esta_instancia.baseframe.rodape.StatusBarCenterAnchor:SetPoint ("center", esta_instancia.baseframe.rodape.top_bg, "center", 20, 58)
				--esta_instancia.baseframe.rodape.esquerdo:SetTexture ("Interface\\AddOns\\Details\\images\\bar_down_left_snap")
				--esta_instancia.baseframe.rodape.esquerdo.have_snap = true

			elseif (lado == 1) then --> esquerda
				--> mover frame
				instancia.baseframe:SetPoint ("TOPLEFT", esta_instancia.baseframe, "TOPRIGHT")
				instancia.baseframe:SetPoint ("LEFT", esta_instancia.baseframe, "RIGHT")
				instancia.baseframe:SetPoint ("BOTTOMLEFT", esta_instancia.baseframe, "BOTTOMRIGHT")
				
				local _, height = esta_instancia:GetSize()
				instancia:SetSize (nil, height)
				
				--> salva o snap
				self.snap [1] = esta_instancia.meu_id
				esta_instancia.snap [3] = self.meu_id
				
			elseif (lado == 2) then --> baixo
				--> mover frame
				
				local statusbar_y_mod = 0
				if (not instancia.show_statusbar) then
					statusbar_y_mod = -14
				end
				
				instancia.baseframe:SetPoint ("BOTTOMLEFT", esta_instancia.baseframe, "TOPLEFT", 0, 34 + statusbar_y_mod)
				instancia.baseframe:SetPoint ("BOTTOM", esta_instancia.baseframe, "TOP", 0, 34 + statusbar_y_mod)
				instancia.baseframe:SetPoint ("BOTTOMRIGHT", esta_instancia.baseframe, "TOPRIGHT", 0, 34 + statusbar_y_mod)
				
				local _, height = esta_instancia:GetSize()
				instancia:SetSize (nil, height)
				
				--> salva o snap
				self.snap [2] = esta_instancia.meu_id
				esta_instancia.snap [4] = self.meu_id
				
				--self.baseframe.rodape.StatusBarLeftAnchor:SetPoint ("left", self.baseframe.rodape.top_bg, "left", 25, 58)
				--self.baseframe.rodape.StatusBarCenterAnchor:SetPoint ("center", self.baseframe.rodape.top_bg, "center", 20, 58)
				--self.baseframe.rodape.esquerdo:SetTexture ([[Interface\AddOns\Details\images\bar_down_left_snap]])
				--self.baseframe.rodape.esquerdo.have_snap = true
			end
			
			if (not esta_instancia.ativa) then
				esta_instancia:AtivarInstancia()
			end
			
		end
	end
	
	gump:Fade (instancia.botao_separar, 0)
	
	if (_detalhes.tutorial.unlock_button < 4) then
	
		_detalhes.temp_table1.IconSize = 32
		_detalhes.temp_table1.TextHeightMod = -6
		_detalhes.popup:ShowMe (instancia.botao_separar, "tooltip", "Interface\\Buttons\\LockButton-Unlocked-Up", Loc ["STRING_UNLOCK"], 150, _detalhes.temp_table1)
		
		UIFrameFlash (instancia.botao_separar, .5, .5, 5, false, 0, 0)
		_detalhes.tutorial.unlock_button = _detalhes.tutorial.unlock_button + 1
	end
	
end

local function FixSnaps (instancia)
	--_detalhes:DelayMsg ("DEBUG verificando snaps para instancia "..instancia.meu_id)
	for snap, esta_instancia in _pairs (instancia.snap) do
		if (esta_instancia) then 
			esta_instancia =  _detalhes.tabela_instancias [esta_instancia]
			--_detalhes:DelayMsg ("DEBUG janela "..instancia.meu_id.." com snap "..snap.. " em " .. esta_instancia.meu_id)
			if (snap == 2) then 
				--instancia.baseframe.rodape.StatusBarLeftAnchor:SetPoint ("left", instancia.baseframe.rodape.top_bg, "left", 25, 10)
				--instancia.baseframe.rodape.StatusBarCenterAnchor:SetPoint ("center", instancia.baseframe.rodape.top_bg, "center", 20, 10)
				--instancia.baseframe.rodape.esquerdo:SetTexture ("Interface\\AddOns\\Details\\images\\bar_down_left_snap")
				--instancia.baseframe.rodape.esquerdo.have_snap = true
			end
		end
	end
end


function _detalhes:Desagrupar (instancia, lado)

	if (self.meu_id) then --> significa que self � uma instancia
		lado = instancia
		instancia = self
	end
	
	if (_type (instancia) == "number") then --> significa que passou o n�mero da inst�ncia
		instancia =  _detalhes.tabela_instancias [instancia]
	end
	
	if (not lado) then
		--print ("DEBUG: Desagrupar esta sem lado")
		return
	end
	
	if (lado < 0) then --> clicou no bot�o para desagrupar tudo
		local ID = instancia.meu_id
		
		for id, esta_instancia in _ipairs (_detalhes.tabela_instancias) do 
			for index, iid in _pairs (esta_instancia.snap) do -- index = 1 left , 3 right, 2 bottom, 4 top
				if (iid and (iid == ID or id == ID)) then -- iid = instancia.meu_id
				
					esta_instancia.snap [index] = nil
					
					if (instancia.verticalSnap or esta_instancia.verticalSnap) then
						if (not esta_instancia.snap [2] and not esta_instancia.snap [4]) then
							esta_instancia.verticalSnap = false
							esta_instancia.horizontalSnap = false
						end
					elseif (instancia.horizontalSnap or esta_instancia.horizontalSnap) then
						if (not esta_instancia.snap [1] and not esta_instancia.snap [3]) then
							esta_instancia.horizontalSnap = false
							esta_instancia.verticalSnap = false
						end
					end
					
					if (index == 2) then  -- index � o codigo do snap
						--esta_instancia.baseframe.rodape.StatusBarLeftAnchor:SetPoint ("left", esta_instancia.baseframe.rodape.top_bg, "left", 5, 58)
						--esta_instancia.baseframe.rodape.StatusBarCenterAnchor:SetPoint ("center", esta_instancia.baseframe.rodape.top_bg, "center", 0, 58)
						--esta_instancia.baseframe.rodape.esquerdo:SetTexture ("Interface\\AddOns\\Details\\images\\bar_down_left")
						--esta_instancia.baseframe.rodape.esquerdo.have_snap = nil
					end
					
				end
			end
		end
		
		gump:Fade (instancia.botao_separar, 1)
		
		instancia.verticalSnap = false
		instancia.horizontalSnap = false
		return
	end
	
	local esta_instancia = _detalhes.tabela_instancias [instancia.snap[lado]]
	
	if (not esta_instancia) then
		--print ("DEBUG: Erro, a instancia nao existe")
		return
	end
	
	instancia.snap [lado] = nil
	
	if (lado == 1) then
		esta_instancia.snap [3] = nil
	elseif (lado == 2) then
		esta_instancia.snap [4] = nil
	elseif (lado == 3) then
		esta_instancia.snap [1] = nil
	elseif (lado == 4) then
		esta_instancia.snap [2] = nil
	end

	gump:Fade (instancia.botao_separar, 1)
	
	if (instancia.iniciada) then
		instancia:SaveMainWindowPosition()
		instancia:RestoreMainWindowPosition()
	end
	
	if (esta_instancia.iniciada) then
		esta_instancia:SaveMainWindowPosition()
		esta_instancia:RestoreMainWindowPosition()	
	end
	
	--print ("DEBUG: Details: Instancias desagrupadas")
	
	--_detalhes:RefreshAgrupamentos()
	
end

function _detalhes:SnapTextures (remove)
	for id, esta_instancia in _ipairs (_detalhes.tabela_instancias) do 
		if (esta_instancia:IsAtiva()) then
			if (esta_instancia.baseframe.rodape.esquerdo.have_snap) then
				if (remove) then
					--esta_instancia.baseframe.rodape.esquerdo:SetTexture ("Interface\\AddOns\\Details\\images\\bar_down_left")
				else
					--esta_instancia.baseframe.rodape.esquerdo:SetTexture ("Interface\\AddOns\\Details\\images\\bar_down_left_snap")
				end
			end
		end
	end
end

--> cria uma janela para uma nova inst�ncia
	--> search key: ~new ~nova
	function _detalhes:NovaInstancia (ID)

		local new_instance = {}
		_setmetatable (new_instance, _detalhes)
		_detalhes.tabela_instancias [#_detalhes.tabela_instancias+1] = new_instance
		
		--> instance number
			new_instance.meu_id = ID
		
		--> setup all config
			new_instance:ResetInstanceConfig()
			--> setup default wallpaper
			local spec = GetSpecialization()
			if (spec) then
				local id, name, description, icon, _background, role = GetSpecializationInfo (spec)
				if (_background) then
					local bg = "Interface\\TALENTFRAME\\" .. _background
					if (new_instance.wallpaper) then
						new_instance.wallpaper.texture = bg
						new_instance.wallpaper.texcoord = {0, 1, 0, 0.703125}
					end
				end
			end

		--> internal stuff
			new_instance.barras = {} --container que ir� armazenar todas as barras
			new_instance.barraS = {nil, nil} --de x at� x s�o as barras que est�o sendo mostradas na tela
			new_instance.rolagem = false --barra de rolagem n�o esta sendo mostrada
			new_instance.largura_scroll = 26
			new_instance.bar_mod = 0
			new_instance.bgdisplay_loc = 0
		
		--> displaying row info
			new_instance.rows_created = 0
			new_instance.rows_showing = 0
			new_instance.rows_max = 50
			new_instance.rows_fit_in_window = nil
		
		--> saved pos for normal mode and lone wolf mode
			new_instance.posicao = {
				["normal"] = {},
				["solo"] = {}
			}		
		--> save information about window snaps
			new_instance.snap = {nil, nil, nil, nil}
		
		--> current state starts as normal
			new_instance.mostrando = "normal"
		--> menu consolidated
			new_instance.consolidate = false
			new_instance.icons = {true, true, true, true}

		--> create window frames
			local _baseframe, _bgframe, _bgframe_display, _scrollframe = gump:CriaJanelaPrincipal (ID, new_instance, true)
			new_instance.baseframe = _baseframe
			new_instance.bgframe = _bgframe
			new_instance.bgdisplay = _bgframe_display
			new_instance.scroll = _scrollframe

		--> status bar stuff
			new_instance.StatusBar = {}
			new_instance.StatusBar.left = nil
			new_instance.StatusBar.center = nil
			new_instance.StatusBar.right = nil
			new_instance.StatusBar.options = {}

			local clock = _detalhes.StatusBar:CreateStatusBarChildForInstance (new_instance, "DETAILS_STATUSBAR_PLUGIN_CLOCK")
			_detalhes.StatusBar:SetCenterPlugin (new_instance, clock)
			
			local segment = _detalhes.StatusBar:CreateStatusBarChildForInstance (new_instance, "DETAILS_STATUSBAR_PLUGIN_PSEGMENT")
			_detalhes.StatusBar:SetLeftPlugin (new_instance, segment)
			
			local dps = _detalhes.StatusBar:CreateStatusBarChildForInstance (new_instance, "DETAILS_STATUSBAR_PLUGIN_PDPS")
			_detalhes.StatusBar:SetRightPlugin (new_instance, dps)

		--> internal stuff
			new_instance.alturaAntiga = _baseframe:GetHeight()
			new_instance.atributo = 1 --> dano 
			new_instance.sub_atributo = 1 --> damage done
			new_instance.sub_atributo_last = {1, 1, 1, 1, 1}
			new_instance.segmento = -1 --> combate atual
			new_instance.modo = modo_grupo
			new_instance.last_modo = modo_grupo
			new_instance.LastModo = modo_grupo
			
		--> change the attribute
			_detalhes:TrocaTabela (new_instance, 0, 1, 1)
			
		--> internal stuff
			new_instance.row_height = new_instance.row_info.height + new_instance.row_info.space.between
			
			new_instance.oldwith = new_instance.baseframe:GetWidth()
			new_instance.iniciada = true
			new_instance:SaveMainWindowPosition()
			new_instance:ReajustaGump()
			
			new_instance.rows_fit_in_window = _math_floor (new_instance.posicao[new_instance.mostrando].h / new_instance.row_height)
		
		--> all done
			new_instance:AtivarInstancia()
			
		new_instance:ShowSideBars()

		--local skin =  fazer aqui o esquema de resgatar a skin salva no profile.
		
		--> apply standard skin if have one saved
			if (_detalhes.standard_skin) then

				local style = _detalhes.standard_skin
				local instance = new_instance
				local skin = style.skin
				
				instance.skin = ""
				instance:ChangeSkin (skin)
				
				--> overwrite all instance parameters with saved ones
				for key, value in pairs (style) do
					if (key ~= "skin") then
						if (type (value) == "table") then
							instance [key] = table_deepcopy (value)
						else
							instance [key] = value
						end
					end
				end

			end
		
		--> apply all changed attributes
		new_instance:ChangeSkin()
		
		return new_instance
	end
------------------------------------------------------------------------------------------------------------------------

	function _detalhes:FixToolbarMenu (instance)
		--print ("fixing...", instance.meu_id)
		--instance:ToolbarMenuButtons()
	end

--> ao reiniciar o addon esta fun��o � rodada para recriar a janela da inst�ncia
--> search key: ~restaura ~inicio ~start
function _detalhes:RestauraJanela (index, temp)
		
	--> load
		self:LoadInstanceConfig()
		
	--> reset internal stuff
		self.sub_atributo_last = self.sub_atributo_last or {1, 1, 1, 1, 1}
		self.rolagem = false
		self.need_rolagem = false
		self.barras = {}
		self.barraS = {nil, nil}
		self.rows_fit_in_window = nil
		self.consolidate = self.consolidate or false
		self.icons = self.icons or {true, true, true, true}
		self.rows_created = 0
		self.rows_showing = 0
		self.rows_max = 50
		self.rows_fit_in_window = nil
		self.largura_scroll = 26
		self.bar_mod = 0
		self.bgdisplay_loc = 0
		self.last_modo = self.last_modo or modo_grupo

		self.row_height = self.row_info.height + self.row_info.space.between
		
	--> create frames
		local instance_baseframe = _G ["DetailsBaseFrame" .. self.meu_id]
		if (instance_baseframe) then
			local _baseframe, _bgframe, _bgframe_display, _scrollframe = instance_baseframe, _G ["Details_WindowFrame" .. self.meu_id], _G ["Details_GumpFrame" .. self.meu_id], _G ["Details_ScrollBar" .. self.meu_id]
			self.baseframe = _baseframe
			self.bgframe = _bgframe
			self.bgdisplay = _bgframe_display
			self.scroll = _scrollframe		
			_baseframe:EnableMouseWheel (false)
			self.alturaAntiga = _baseframe:GetHeight()
		else
			local _baseframe, _bgframe, _bgframe_display, _scrollframe = gump:CriaJanelaPrincipal (self.meu_id, self)
			self.baseframe = _baseframe
			self.bgframe = _bgframe
			self.bgdisplay = _bgframe_display
			self.scroll = _scrollframe		
			_baseframe:EnableMouseWheel (false)
			self.alturaAntiga = _baseframe:GetHeight()
		end
	

		
	--> change the attribute
		_detalhes:TrocaTabela (self, self.segmento, self.atributo, self.sub_atributo, true) --> passando true no 5� valor para a fun��o ignorar a checagem de valores iguais
	
	--> set wallpaper
		if (self.wallpaper.enabled) then
			self:InstanceWallpaper (true)
		end
		
	--> set the color of this instance window
		self:InstanceColor (self.color)
		
	--> scrollbar
		self:EsconderScrollBar (true)
	
	--> check snaps
		self.snap = self.snap or {nil, nil, nil, nil}
		FixSnaps (self)

	--> status bar stuff
		self.StatusBar = {}
		self.StatusBar.left = nil
		self.StatusBar.center = nil
		self.StatusBar.right = nil
		self.StatusBarSaved = self.StatusBarSaved or {options = {}}
		self.StatusBar.options = self.StatusBarSaved.options

		if (self.StatusBarSaved.center and self.StatusBarSaved.center == "NONE") then
			self.StatusBarSaved.center = "DETAILS_STATUSBAR_PLUGIN_CLOCK"
		end
		local clock = _detalhes.StatusBar:CreateStatusBarChildForInstance (self, self.StatusBarSaved.center or "DETAILS_STATUSBAR_PLUGIN_CLOCK")
		_detalhes.StatusBar:SetCenterPlugin (self, clock, true)
		
		if (self.StatusBarSaved.left and self.StatusBarSaved.left == "NONE") then
			self.StatusBarSaved.left = "DETAILS_STATUSBAR_PLUGIN_PSEGMENT"
		end
		local segment = _detalhes.StatusBar:CreateStatusBarChildForInstance (self, self.StatusBarSaved.left or "DETAILS_STATUSBAR_PLUGIN_PSEGMENT")
		_detalhes.StatusBar:SetLeftPlugin (self, segment, true)
		
		if (self.StatusBarSaved.right and self.StatusBarSaved.right == "NONE") then
			self.StatusBarSaved.right = "DETAILS_STATUSBAR_PLUGIN_PDPS"
		end
		local dps = _detalhes.StatusBar:CreateStatusBarChildForInstance (self, self.StatusBarSaved.right or "DETAILS_STATUSBAR_PLUGIN_PDPS")
		_detalhes.StatusBar:SetRightPlugin (self, dps, true)

	--> load mode

		if (self.modo == modo_alone) then
			if (_detalhes.solo and _detalhes.solo ~= self.meu_id) then --> prote��o para ter apenas uma inst�ncia com a janela SOLO
				self.modo = modo_grupo
				self.mostrando = "normal"
			else
				self:SoloMode (true)
				_detalhes.solo = self.meu_id
			end
		elseif (self.modo == modo_raid) then
			_detalhes.raid = self.meu_id
		else
			self.mostrando = "normal"
		end

	--> internal stuff
		self.oldwith = self.baseframe:GetWidth()
		self:RestoreMainWindowPosition()
		self:ReajustaGump()
		self:SaveMainWindowPosition()
		
		self.iniciada = true
		self:AtivarInstancia (temp)
		
		self:ChangeSkin()
		
	--> all done
	
end

function _detalhes:ExportSkin()

	--create the table
	local exported = {
		version = _detalhes.preset_version --skin version
	}

	--export the keys
	for key, value in pairs (self) do
		if (_detalhes.instance_defaults [key] ~= nil) then	
			if (type (value) == "table") then
				exported [key] = table_deepcopy (value)
			else
				exported [key] = value
			end
		end
	end
	
	--export mini displays
	if (self.StatusBar and self.StatusBar.left) then
		exported.StatusBarSaved = {
			["left"] = self.StatusBar.left.real_name or "NONE",
			["center"] = self.StatusBar.center.real_name or "NONE",
			["right"] = self.StatusBar.right.real_name or "NONE",
		}
		exported.StatusBarSaved.options = {
			[exported.StatusBarSaved.left] = table_deepcopy (self.StatusBar.left.options),
			[exported.StatusBarSaved.center] = table_deepcopy (self.StatusBar.center.options),
			[exported.StatusBarSaved.right] = table_deepcopy (self.StatusBar.right.options)
		}

	elseif (self.StatusBarSaved) then
		exported.StatusBarSaved = table_deepcopy (self.StatusBarSaved)
		
	end

	return exported
	
end

function _detalhes:ApplySavedSkin (style)

	if (not style.version or _detalhes.preset_version > style.version) then
		return _detalhes:Msg (Loc ["STRING_OPTIONS_PRESETTOOLD"])
	end
	
	--> set skin preset
	local skin = style.skin
	self.skin = ""
	self:ChangeSkin (skin)
	
	-- /script print (_detalhes.tabela_instancias[1].baseframe:GetAlpha())

	--> overwrite all instance parameters with saved ones
	for key, value in pairs (style) do
		if (key ~= "skin") then
			if (type (value) == "table") then
				self [key] = table_deepcopy (value)
			else
				self [key] = value
			end
		end
	end
	
	--> check for new keys inside tables
	for key, value in pairs (_detalhes.instance_defaults) do 
		if (type (value) == "table") then
			for key2, value2 in pairs (value) do 
				if (self [key] [key2] == nil) then
					if (type (value2) == "table") then
						self [key] [key2] = table_deepcopy (_detalhes.instance_defaults [key] [key2])
					else
						self [key] [key2] = value2
					end
				end
			end
		end
	end	
	
	self.StatusBarSaved = style.StatusBarSaved and table_deepcopy (style.StatusBarSaved) or {options = {}}
	self.StatusBar.options = self.StatusBarSaved.options
	_detalhes.StatusBar:UpdateChilds (self)
	
	--> apply all changed attributes
	self:ChangeSkin()
end

------------------------------------------------------------------------------------------------------------------------

function _detalhes:InstanceReset (instance)
	if (instance) then
		self = instance
	end
	_detalhes.gump:Fade (self, "in", nil, "barras")
	self:AtualizaSegmentos (self)
	self:AtualizaSoloMode_AfertReset()
	self:ResetaGump()
	_detalhes:AtualizaGumpPrincipal (self, true) --atualiza todas as instancias
end

function _detalhes:RefreshBars (instance)
	if (instance) then
		self = instance
	end
	self:InstanceRefreshRows (instancia)
end

function _detalhes:SetBackgroundColor (...)

	local red = select (1, ...)
	if (not red) then
		self.bgdisplay:SetBackdropColor (self.bg_r, self.bg_g, self.bg_b, self.bg_alpha)
		self.baseframe:SetBackdropColor (self.bg_r, self.bg_g, self.bg_b, self.bg_alpha)
		return
	end

	local r, g, b = gump:ParseColors (...)
	self.bgdisplay:SetBackdropColor (r, g, b, self.bg_alpha or _detalhes.default_bg_alpha)
	self.baseframe:SetBackdropColor (r, g, b, self.bg_alpha or _detalhes.default_bg_alpha)
	self.bg_r = r
	self.bg_g = g
	self.bg_b = b
end

function _detalhes:SetBackgroundAlpha (alpha)
	if (not alpha) then
		alpha = self.bg_alpha
--	else
--		print (alpha)
--		alpha = _detalhes:Scale (0, 1, 0.2, 1, alpha) - 0.8
	end
	
	self.bgdisplay:SetBackdropColor (self.bg_r, self.bg_g, self.bg_b, alpha)
	self.baseframe:SetBackdropColor (self.bg_r, self.bg_g, self.bg_b, alpha)
	self.bg_alpha = alpha
end

function _detalhes:GetSize()
	return self.bgframe:GetWidth(), self.bgframe:GetHeight()
end

--> alias
function _detalhes:SetSize (w, h)
	return self:Resize (w, h)
end

function _detalhes:Resize (w, h)
	if (w) then
		self.baseframe:SetWidth (w)
	end
	
	if (h) then
		self.baseframe:SetHeight (h)
	end
	
	self:SaveMainWindowPosition()
	
	return true
end

------------------------------------------------------------------------------------------------------------------------

function _detalhes:HaveOneCurrentInstance()

	local have = false
	for _, instance in _ipairs (_detalhes.tabela_instancias) do
		if (instance.ativa and instance.baseframe and instance.segmento == 0) then
			return
		end
	end
	
	local lower = _detalhes:GetLowerInstanceNumber()
	if (lower) then
		local instance = _detalhes:GetInstance (lower)
		if (instance and instance.auto_current) then
			instance:TrocaTabela (0) --> muda o segmento pra current
			return instance:InstanceAlert (Loc ["STRING_CHANGED_TO_CURRENT"], {[[Interface\GossipFrame\TrainerGossipIcon]], 18, 18, false}, 6)
		else
			for _, instance in _ipairs (_detalhes.tabela_instancias) do
				if (instance.ativa and instance.baseframe and instance.segmento ~= 0 and instance.auto_current) then
					instance:TrocaTabela (0) --> muda o segmento pra current
					return instance:InstanceAlert (Loc ["STRING_CHANGED_TO_CURRENT"], {[[Interface\GossipFrame\TrainerGossipIcon]], 18, 18, false}, 6)
				end
			end
		end
	end
	
end

function _detalhes:Freeze (instancia)

	if (not instancia) then
		instancia = self
	end

	if (not _detalhes.initializing) then
		instancia:ResetaGump()
		gump:Fade (instancia, "in", nil, "barras")
	end
	
	instancia:InstanceMsg (Loc ["STRING_FREEZE"], [[Interface\CHARACTERFRAME\Disconnect-Icon]], "silver")
	
	--instancia.freeze_icon:Show()
	--instancia.freeze_texto:Show()
	
	local width = instancia:GetSize()
	instancia.freeze_texto:SetWidth (width-64)
	
	instancia.freezed = true
end

function _detalhes:UnFreeze (instancia)

	if (not instancia) then
		instancia = self
	end

	self:InstanceMsg (false)
	
	--instancia.freeze_icon:Hide()
	--instancia.freeze_texto:Hide()
	instancia.freezed = false
	
	if (not _detalhes.initializing) then
		--instancia:RestoreMainWindowPosition()
		instancia:ReajustaGump()
	end
end

function _detalhes:AtualizaSegmentos (instancia)
	if (instancia.iniciada) then
		if (instancia.segmento == -1) then
			--instancia.baseframe.rodape.segmento:SetText (segmentos.overall) --> localiza-me
			instancia.showing = _detalhes.tabela_overall
		elseif (instancia.segmento == 0) then
			--instancia.baseframe.rodape.segmento:SetText (segmentos.current) --> localiza-me
			instancia.showing = _detalhes.tabela_vigente
		else
			instancia.showing = _detalhes.tabela_historico.tabelas [instancia.segmento]
			--instancia.baseframe.rodape.segmento:SetText (segmentos.past..instancia.segmento) --> localiza-me
		end
	end
end

function _detalhes:AtualizaSegmentos_AfterCombat (instancia, historico)

	if (instancia.freezed) then
		return --> se esta congelada n�o tem o que fazer
	end

	local segmento = instancia.segmento

	local _fadeType, _fadeSpeed = _unpack (_detalhes.row_fade_in)
	
	if (segmento == _detalhes.segments_amount) then --> significa que o index [5] passou a ser [6] com a entrada da nova tabela
		instancia.showing = historico.tabelas [_detalhes.segments_amount] --> ent�o ele volta a pegar o index [5] que antes era o index [4]

		gump:Fade (instancia, _fadeType, _fadeSpeed, "barras")
		instancia.showing[instancia.atributo].need_refresh = true
		instancia.v_barras = true
		instancia:ResetaGump()
		instancia:AtualizaGumpPrincipal (true)
		
	elseif (segmento < _detalhes.segments_amount and segmento > 0) then
		instancia.showing = historico.tabelas [segmento]
		
		gump:Fade (instancia, _fadeType, _fadeSpeed, "barras") --"in", nil
		instancia.showing[instancia.atributo].need_refresh = true
		instancia.v_barras = true
		instancia:ResetaGump()
		instancia:AtualizaGumpPrincipal (true)
	end
	
end

function _detalhes:TrocaTabela (instancia, segmento, atributo, sub_atributo, iniciando_instancia, InstanceMode)

	if (self and self.meu_id and not instancia) then --> self � uma inst�ncia
		InstanceMode = iniciando_instancia
		iniciando_instancia = sub_atributo
		sub_atributo = atributo
		atributo = segmento
		segmento = instancia
		instancia = self
	end
	
	if (_type (instancia) == "number") then
		sub_atributo = atributo
		atributo = segmento
		segmento = instancia
		instancia = self
	end
	
	if (InstanceMode and InstanceMode ~= instancia:GetMode()) then
		instancia:AlteraModo (instancia, InstanceMode)
	end
	
	local update_coolTip = false
	local sub_attribute_click = false
	
	if (_type (segmento) == "boolean" and segmento) then --> clicou em um sub atributo
		sub_attribute_click = true
		segmento = instancia.segmento
	
	elseif (segmento == -2) then --> clicou para mudar de segmento
		segmento = instancia.segmento + 1
		
		if (segmento > _detalhes.segments_amount) then
			segmento = -1
		end
		update_coolTip = true
		
	elseif (segmento == -3) then --> clicou para mudar de atributo
		segmento = instancia.segmento
		
		atributo = instancia.atributo+1
		if (atributo > atributos[0]) then
			atributo = 1
		end
		update_coolTip = true
		
	elseif (segmento == -4) then --> clicou para mudar de sub atributo
		segmento = instancia.segmento
		
		sub_atributo = instancia.sub_atributo+1
		if (sub_atributo > atributos[instancia.atributo]) then
			sub_atributo = 1
		end
		update_coolTip = true
		
	end	
	
	--> pega os atributos desta instancia
	local current_segmento = instancia.segmento
	local current_atributo = instancia.atributo
	local current_sub_atributo = instancia.sub_atributo
	
	local atributo_changed = false
	
	--> verifica possiveis valores n�o passados
	
	if (not segmento) then
		segmento = instancia.segmento
	end
	if (not atributo) then
		atributo  = instancia.atributo
	end
	if (not sub_atributo) then
		if (atributo == current_atributo) then
			sub_atributo  = instancia.sub_atributo
		else
			sub_atributo  = instancia.sub_atributo_last [atributo]
		end
	end
	
	--> j� esta mostrando isso que esta pedindo
	if (not iniciando_instancia and segmento == current_segmento and atributo == current_atributo and sub_atributo == current_sub_atributo and not _detalhes.initializing) then
		return
	end

	--> Muda o segmento caso necess�rio
	if (segmento ~= current_segmento or _detalhes.initializing or iniciando_instancia) then

		--> na troca de segmento, conferir se a instancia esta frozen
		if (instancia.freezed) then
			if (not iniciando_instancia) then
				instancia:UnFreeze()
			else
				instancia.freezed = false
			end
		end
	
		instancia.segmento = segmento
	
		if (segmento == -1) then --> overall
			instancia.showing = _detalhes.tabela_overall
		elseif (segmento == 0) then --> combate atual
			instancia.showing = _detalhes.tabela_vigente
		else --> alguma tabela do hist�rico
			instancia.showing = _detalhes.tabela_historico.tabelas [segmento]
		end
		
		if (update_coolTip) then
			_detalhes.popup:Select (1, segmento+2)
		end
		
		if (instancia.showing and instancia.showing.contra) then
			--print ("DEBUG: contra", instancia.showing.contra)
		end

		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGESEGMENT", nil, instancia, segmento)
		
	end

	--> Muda o atributo caso  necess�rio
	--print ("DEBUG atributos", instancia, segmento, atributo, sub_atributo, iniciando_instancia)

	if (atributo == 5) then
		if (#_detalhes.custom < 1) then 
			atributo = 1
			sub_atributo = 1
		end
	end
	
	if (atributo ~= current_atributo or _detalhes.initializing or iniciando_instancia or (instancia.modo == modo_alone or instancia.modo == modo_raid)) then
	
		if (instancia.modo == modo_alone and not (_detalhes.initializing or iniciando_instancia)) then
			if (_detalhes.SoloTables.Mode == #_detalhes.SoloTables.Plugins) then
				_detalhes.popup:Select (1, 1)
			else
				if (_detalhes.PluginCount.SOLO > 0) then
					_detalhes.popup:Select (1, _detalhes.SoloTables.Mode+1)
				end
			end
			return _detalhes.SoloTables.switch (nil, nil, -1)
	
		elseif ( (instancia.modo == modo_raid) and not (_detalhes.initializing or iniciando_instancia) ) then --> raid
			if (_detalhes.RaidTables.Mode == #_detalhes.RaidTables.Plugins) then
				_detalhes.popup:Select (1, 1)
			else
				if (_detalhes.PluginCount.RAID > 0) then
					_detalhes.popup:Select (1, _detalhes.RaidTables.Mode+1)
				end
				
			end
			return _detalhes.RaidTables.switch (nil, nil, -1)
		end
		
		atributo_changed = true
		instancia.atributo = atributo
		instancia.sub_atributo = instancia.sub_atributo_last [atributo]
		
		--> troca icone
		instancia:ChangeIcon()
		
		if (update_coolTip) then
			_detalhes.popup:Select (1, atributo)
			_detalhes.popup:Select (2, instancia.sub_atributo, atributo)
		end
		
		if (_detalhes.cloud_process) then
			
			if (_detalhes.debug) then
				_detalhes:Msg ("(debug) instancia #"..instancia.meu_id.." found cloud process.")
			end
			
			local atributo = instancia.atributo
			local time_left = (_detalhes.last_data_requested+7) - _detalhes._tempo
			
			if (atributo == 1 and _detalhes.in_combat and not _detalhes:CaptureGet ("damage") and _detalhes.host_by) then
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) instancia need damage cloud.")
				end
			elseif (atributo == 2 and _detalhes.in_combat and (not _detalhes:CaptureGet ("heal") or _detalhes:CaptureGet ("aura")) and _detalhes.host_by) then
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) instancia need heal cloud.")
				end
			elseif (atributo == 3 and _detalhes.in_combat and not _detalhes:CaptureGet ("energy") and _detalhes.host_by) then
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) instancia need energy cloud.")
				end
			elseif (atributo == 4 and _detalhes.in_combat and not _detalhes:CaptureGet ("miscdata") and _detalhes.host_by) then
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) instancia need misc cloud.")
				end
			else
				time_left = nil
			end
			
			if (time_left) then
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) showing instance alert.")
				end
				instancia:InstanceAlert (Loc ["STRING_PLEASE_WAIT"], {[[Interface\COMMON\StreamCircle]], 22, 22, true}, time_left)
			end
		end
		
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEATTRIBUTE", nil, instancia, atributo, sub_atributo)
		
	end

	if (sub_atributo ~= current_sub_atributo or _detalhes.initializing or iniciando_instancia or atributo_changed) then
		
		instancia.sub_atributo = sub_atributo
		
		if (sub_attribute_click) then
			instancia.sub_atributo_last [instancia.atributo] = instancia.sub_atributo
		end
		
		if (instancia.atributo == 5) then --> custom
			instancia:ChangeIcon()
		end
		
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEATTRIBUTE", nil, instancia, atributo, sub_atributo)
	end

	if (not instancia.showing) then
		if (not iniciando_instancia) then
			instancia:Freeze()
		end
		return
	else
		--> verificar relogio, precisaria dar refresh no plugin clock
	end
	
	instancia.v_barras = true
	
	instancia.showing [atributo].need_refresh = true
	
	if (not _detalhes.initializing and not iniciando_instancia) then
		instancia:ResetaGump()
		--print ("atualizando: ", instancia.atributo, instancia.sub_atributo)
		instancia:AtualizaGumpPrincipal (true)
	end

end

function _detalhes:MontaRaidOption (instancia)
	for index, ptable in _ipairs (_detalhes.RaidTables.Menu) do
		if (ptable [3].__enabled) then
			GameCooltip:AddMenu (1, _detalhes.RaidTables.switch, index, nil, nil, ptable [1], ptable [2], true)
		end
	end
	
	if (_detalhes.RaidTables.Mode and _detalhes.RaidTables.Mode == index) then
		GameCooltip:SetLastSelected (1, _detalhes.RaidTables.Mode)
	end
	
	GameCooltip:SetWallpaper (1, [[Interface\SPELLBOOK\Spellbook-Page-1]], {.6, 0.1, 0, 0.64453125}, {1, 1, 1, 0.1}, true)
end

function _detalhes:MontaSoloOption (instancia)
	for index, ptable in _ipairs (_detalhes.SoloTables.Menu) do 
		if (ptable [3].__enabled) then
			GameCooltip:AddMenu (1, _detalhes.SoloTables.switch, index, nil, nil, ptable [1], ptable [2], true)
		end
	end
	
	if (_detalhes.SoloTables.Mode) then
		GameCooltip:SetLastSelected (1, _detalhes.SoloTables.Mode)
	end
	
	GameCooltip:SetWallpaper (1, [[Interface\SPELLBOOK\Spellbook-Page-1]], {.6, 0.1, 0, 0.64453125}, {1, 1, 1, 0.1}, true)
end

-- ~menu
function _detalhes:MontaAtributosOption (instancia, func)

	func = func or instancia.TrocaTabela

	local checked1 = instancia.atributo
	local atributo_ativo = instancia.atributo --> pega o numero
	
	local options
	if (atributo_ativo == 5) then --> custom
		options = {Loc ["STRING_CUSTOM_NEW"]}
		for index, custom in _ipairs (_detalhes.custom) do 
			options [#options+1] = custom.name
		end
	else
		options = sub_atributos [atributo_ativo].lista
	end
	
	local icones = {
		"Interface\\AddOns\\Details\\images\\atributos_icones_damage", 
		"Interface\\AddOns\\Details\\images\\atributos_icones_heal", 
		"Interface\\AddOns\\Details\\images\\atributos_icones_energyze",
		"Interface\\AddOns\\Details\\images\\atributos_icones_misc"
	}

	local CoolTip = _G.GameCooltip
	local p = 0.125 --> 32/256
	
	local gindex = 1
	for i = 1, atributos[0] do --> [0] armazena quantos atributos existem
		
		CoolTip:AddMenu (1, func, nil, i, nil, atributos.lista[i], nil, true)
		CoolTip:AddIcon ("Interface\\AddOns\\Details\\images\\atributos_icones", 1, 1, 20, 20, p*(i-1), p*(i), 0, 1)
		
		if (i == 1) then
			CoolTip:SetWallpaper (2, [[Interface\TALENTFRAME\WarlockDestruction-TopLeft]], {1, 0.22, 0, 0.55}, {1, 1, 1, .1})
		elseif (i == 2) then
			--CoolTip:SetWallpaper (2, [[Interface\TALENTFRAME\PriestHoly-TopLeft]], {0, .8, 0, 1}, {1, 1, 1, .1})
			CoolTip:SetWallpaper (2, [[Interface\TALENTFRAME\bg-priest-holy]], {1, .6, 0, .2}, {1, 1, 1, .2})
		elseif (i == 3) then
			CoolTip:SetWallpaper (2, [[Interface\TALENTFRAME\ShamanEnhancement-TopLeft]], {0, 1, .2, .6}, {1, 1, 1, .1})
		elseif (i == 4) then
			CoolTip:SetWallpaper (2, [[Interface\TALENTFRAME\WarlockCurses-TopLeft]], {.2, 1, 0, 1}, {1, 1, 1, .1})
		end
		
		local options = sub_atributos [i].lista
		
		for o = 1, atributos [i] do
			if (_detalhes:CaptureIsEnabled ( _detalhes.atributos_capture [gindex] )) then
				CoolTip:AddMenu (2, func, true, i, o, options[o], nil, true)
				CoolTip:AddIcon (icones[i], 2, 1, 20, 20, p*(o-1), p*(o), 0, 1)
			else
				CoolTip:AddLine (options[o], nil, 2, .5, .5, .5, 1)
				CoolTip:AddMenu (2, func, true, i, o)
				CoolTip:AddIcon (icones[i], 2, 1, 20, 20, p*(o-1), p*(o), 0, 1, {.3, .3, .3, 1})
			end

			gindex = gindex + 1
		end

		CoolTip:SetLastSelected (2, i, instancia.sub_atributo_last [i])

	end
	
	--> custom
	CoolTip:AddMenu (1, func, nil, 5, nil, atributos.lista[5], nil, true)
	CoolTip:AddIcon ("Interface\\AddOns\\Details\\images\\atributos_icones", 1, 1, 20, 20, p*(5-1), p*(5), 0, 1)
	CoolTip:AddMenu (2, _detalhes.OpenCustomWindow, nil, nil, nil, Loc ["STRING_CUSTOM_NEW"], "Interface\\PaperDollInfoFrame\\Character-Plus", true)
	
	for index, custom in _ipairs (_detalhes.custom) do 
		CoolTip:AddMenu (2, func, nil, 5, index, custom.name, custom.icon, true)
	end

	if (#_detalhes.custom == 0) then
		CoolTip:SetLastSelected (2, 5, 1)
	else
		CoolTip:SetLastSelected (2, 5, instancia.sub_atributo_last [5]+1)
	end

	CoolTip:SetLastSelected (1, atributo_ativo)
	
	CoolTip:SetWallpaper (1, [[Interface\SPELLBOOK\Spellbook-Page-1]], {.6, 0.1, 0, 0.64453125}, {1, 1, 1, 0.1}, true)
	--CoolTip:SetWallpaper (1, [[Interface\ACHIEVEMENTFRAME\UI-Achievement-Parchment-Horizontal-Desaturated]], nil, {1, 1, 1, 0.3})
	
	return menu_principal, sub_menus
end

--> O Modo n�o vai afetar a tabela do SHOWING.
-- o modo � apenas afetado na hora de mostrar o que na tabela

function _detalhes:ChangeIcon (icon)
	
	local skin = _detalhes.skins [self.skin]

	if (icon) then
		
		--> plugin chamou uma troca de icone
		self.baseframe.cabecalho.atributo_icon:SetTexture (icon)
		self.baseframe.cabecalho.atributo_icon:SetTexCoord (5/64, 60/64, 3/64, 62/64)
		
		local icon_size = skin.icon_plugins_size
		self.baseframe.cabecalho.atributo_icon:SetWidth (icon_size[1])
		self.baseframe.cabecalho.atributo_icon:SetHeight (icon_size[2])
		local icon_anchor = skin.icon_anchor_plugins
		self.baseframe.cabecalho.atributo_icon:SetPoint ("TOPRIGHT", self.baseframe.cabecalho.ball_point, "TOPRIGHT", icon_anchor[1], icon_anchor[2])
		
	elseif (self.modo == modo_alone) then --> solo
		-- o icone � alterado pelo pr�prio plugin
	
	elseif (self.modo == modo_grupo or self.modo == modo_all) then --> grupo

		if (self.atributo == 5) then 
			--> custom
			if (_detalhes.custom [self.sub_atributo]) then
				local icon = _detalhes.custom [self.sub_atributo].icon
				self.baseframe.cabecalho.atributo_icon:SetTexture (icon)
				self.baseframe.cabecalho.atributo_icon:SetTexCoord (5/64, 60/64, 3/64, 62/64)
				
				local icon_size = skin.icon_plugins_size
				self.baseframe.cabecalho.atributo_icon:SetWidth (icon_size[1])
				self.baseframe.cabecalho.atributo_icon:SetHeight (icon_size[2])
				local icon_anchor = skin.icon_anchor_plugins
				self.baseframe.cabecalho.atributo_icon:SetPoint ("TOPRIGHT", self.baseframe.cabecalho.ball_point, "TOPRIGHT", icon_anchor[1], icon_anchor[2])
			end
		else
			--> normal
			local half = 0.00048828125
			local size = 0.03125
			self.baseframe.cabecalho.atributo_icon:SetTexture (skin.file)
			self.baseframe.cabecalho.atributo_icon:SetTexCoord ( (0.03125 * (self.atributo-1)) + half, (0.03125 * self.atributo) - half, 0.35693359375, 0.38720703125)
			
			local icon_anchor = skin.icon_anchor_main
			self.baseframe.cabecalho.atributo_icon:SetPoint ("TOPRIGHT", self.baseframe.cabecalho.ball_point, "TOPRIGHT", icon_anchor[1], icon_anchor[2])
			
			self.baseframe.cabecalho.atributo_icon:SetWidth (32)
			self.baseframe.cabecalho.atributo_icon:SetHeight (32)
		end
		
	elseif (self.modo == modo_raid) then --> raid
		-- o icone � alterado pelo pr�prio plugin
	end
end

function _detalhes:AlteraModo (instancia, qual)

	if (_type (instancia) == "number") then
		qual = instancia
		instancia = self
	end
	
	local update_coolTip = false
	
	if (qual == -2) then --clicou para mudar
		local update_coolTip = true
		
		if (instancia.modo == 1) then
			qual = 2
		elseif (instancia.modo == 2) then
			qual = 3
		elseif (instancia.modo == 3) then
			qual = 4
		elseif (instancia.modo == 4) then
			qual = 1
		end
	end
	
	--[[ if (_detalhes.solo and _detalhes.solo == instancia.meu_id) then --> n�o trocar de modo se tiver em combate e a janela no solo mode
		if (UnitAffectingCombat ("player")) then
			return
		end
	end --]]

	if (instancia.showing) then
		if (not instancia.atributo) then
			instancia.atributo = 1
			instancia.sub_atributo = 1
			print ("Details found a internal probleam and fixed: 'instancia.atributo' were null, now is 1.")
		end
		if (not instancia.showing[instancia.atributo]) then
			instancia.showing = _detalhes.tabela_vigente
			print ("Details found a internal problem and fixed: container for instancia.showing were null, now is current combat.")
		end
		instancia.atributo = instancia.atributo or 1
		instancia.showing[instancia.atributo].need_refresh = true
	end
	
	if (qual == modo_alone) then
	
		instancia.LastModo = instancia.modo
	
		if (instancia:IsRaidMode()) then
			instancia:RaidMode (false, instancia)
		end

		--> verifica se ja tem alguma instancia desativada em solo e remove o solo dela
		_detalhes:InstanciaCallFunctionOffline (_detalhes.InstanciaCheckForDisabledSolo)
		
		instancia.modo = modo_alone
		instancia:ChangeIcon()
		
		instancia:SoloMode (true)
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEMODE", nil, instancia, modo_alone)
		
	elseif (qual == modo_raid) then
		
		instancia.LastModo = instancia.modo
		
		if (instancia:IsSoloMode()) then
			instancia:SoloMode (false)
		end

		_detalhes:InstanciaCallFunctionOffline (_detalhes.InstanciaCheckForDisabledRaid)
		
		instancia.modo = modo_raid
		instancia:ChangeIcon()
		
		_detalhes:RaidMode (true, instancia)
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEMODE", nil, instancia, modo_raid)
	
	elseif (qual == modo_grupo) then
	
		instancia.LastModo = instancia.modo
	
		if (instancia:IsSoloMode()) then
			--instancia.modo = modo_grupo
			instancia:SoloMode (false)
		elseif (instancia:IsRaidMode()) then
			instancia:RaidMode (false, instancia)
		end
		
		_detalhes:ResetaGump (instancia)
		--gump:Fade (instancia, 1, nil, "barras")
		
		instancia.modo = modo_grupo
		instancia:ChangeIcon()
		
		instancia:AtualizaGumpPrincipal (true)
		instancia.last_modo = modo_grupo
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEMODE", nil, instancia, modo_grupo)

	elseif (qual == modo_all) then
	
		instancia.LastModo = instancia.modo
	
		if (instancia:IsSoloMode()) then
			instancia.modo = modo_all
			instancia:SoloMode (false)

		elseif (instancia:IsRaidMode()) then
			instancia:RaidMode (false, instancia)
		end
		
		instancia.modo = modo_all
		instancia:ChangeIcon()
		
		instancia:AtualizaGumpPrincipal (true)
		instancia.last_modo = modo_all
		_detalhes:SendEvent ("DETAILS_INSTANCE_CHANGEMODE", nil, instancia, modo_all)
	end
	
	local checked
	if (instancia.modo == 1) then
		checked = 3
	elseif (instancia.modo == 2) then
		checked = 1
	elseif (instancia.modo == 3) then
		checked = 2
	elseif (instancia.modo == 4) then
		checked = 4
	end	
	
	_detalhes.popup:Select (1, checked)
end

local function GetDpsHps (_thisActor, key)

	local keyname
	if (key == "dps") then
		keyname = "last_dps"
	elseif (key == "hps") then
		keyname = "last_hps"
	end
		
	if (_thisActor [keyname]) then
		return _thisActor [keyname]
	else
		if ((_detalhes.time_type == 2 and _thisActor.grupo) or not _detalhes:CaptureGet ("damage")) then
			local dps = _thisActor.total / _thisActor:GetCombatTime()
			_thisActor [keyname] = dps
			return dps
		else
			if (not _thisActor.on_hold) then
				local dps = _thisActor.total/_thisActor:Tempo() --calcula o dps deste objeto
				_thisActor [keyname] = dps --salva o dps dele
				return dps
			else
				if (_thisActor [keyname] == 0) then --> n�o calculou o dps dele ainda mas entrou em standby
					local dps = _thisActor.total/_thisActor:Tempo()
					_thisActor [keyname] = dps
					return dps
				else
					return _thisActor [keyname]
				end
			end
		end
	end
end

--> Reportar o que esta na janela da inst�ncia
function _detalhes:monta_relatorio (este_relatorio, custom)
	
	if (custom) then
		--> shrink
		local report_lines = {}
		
		for i = 1, _detalhes.report_lines+1, 1 do  --#este_relatorio -- o +1 � pq ele conta o cabe�alho como uma linha
			report_lines [#report_lines+1] = este_relatorio[i]
		end
		
		return self:envia_relatorio (report_lines, true)
	end
	
	local amt = _detalhes.report_lines

	local report_lines = {}

	if (self.atributo == 5) then --> custom
		report_lines [#report_lines+1] = "Details!: " .. self.customName .. " " .. Loc ["STRING_CUSTOM_REPORT"]
	else
		report_lines [#report_lines+1] = "Details!: " .. _detalhes.sub_atributos [self.atributo].lista [self.sub_atributo]
	end
	
	local barras = self.barras
	local esta_barra
	
	local is_current = _G ["Details_Report_CB_1"]:GetChecked()
	local is_reverse = _G ["Details_Report_CB_2"]:GetChecked()
	
	if (not _detalhes.fontstring_len) then
		_detalhes.fontstring_len = _detalhes.listener:CreateFontString (nil, "background", "GameFontNormal")
	end
	local _, fontSize = FCF_GetChatWindowInfo (1)
	if (fontSize < 1) then
		fontSize = 10
	end
	local fonte, _, flags = _detalhes.fontstring_len:GetFont()
	_detalhes.fontstring_len:SetFont (fonte, fontSize, flags)
	_detalhes.fontstring_len:SetText ("hello details!")
	local default_len = _detalhes.fontstring_len:GetStringWidth()
	
	--> pegar a font do chat
	--_detalhes.fontstring_len:
	
	if (not is_reverse) then
	
		if (not is_current) then 
			--> assumindo que self � sempre uma inst�ncia aqui.
			local total, keyName, keyNameSec, first
			local atributo = self.atributo
			local container = self.showing [atributo]._ActorTable
			
			--print ("amt: ",#container)
			
			if (atributo == 1) then --> damage
				if (self.sub_atributo == 5) then --> frags
					local frags = self.showing.frags
					local reportarFrags = {}
					for name, amount in pairs (frags) do 
						--> string para imprimir direto sem calculos
						reportarFrags [#reportarFrags+1] = {frag = tostring (amount), nome = name} 
					end
					container = reportarFrags
					keyName = "frag"
				else
					total, keyName, first = _detalhes.atributo_damage:RefreshWindow (self, self.showing, true, true)
					if (self.sub_atributo == 1) then
						keyNameSec = "dps"
					end
				end
			elseif (atributo == 2) then --> heal
				total, keyName, first = _detalhes.atributo_heal:RefreshWindow (self, self.showing, true, true)
				if (self.sub_atributo == 1) then
					keyNameSec = "hps"
				end
			elseif (atributo == 3) then --> energy
				total, keyName, first = _detalhes.atributo_energy:RefreshWindow (self, self.showing, true, true)
			elseif (atributo == 4) then --> misc
				if (self.sub_atributo == 5) then --> mortes
					local mortes = self.showing.last_events_tables
					local reportarMortes = {}
					for index, morte in ipairs (mortes) do 
						reportarMortes [#reportarMortes+1] = {dead = morte [6], nome = morte [3]:gsub (("%-.*"), "")}
					end
					container = reportarMortes
					keyName = "dead"
				else
					total, keyName, first = _detalhes.atributo_misc:RefreshWindow (self, self.showing, true, true)
				end
			elseif (atributo == 5) then --> custom
			
				if (_detalhes.custom [self.sub_atributo]) then
					total, keyName, first = _detalhes.atributo_custom:RefreshWindow (self, self.showing, true, {key = "custom"})
					total = self.showing.totals [self.customName]
					atributo = _detalhes.custom [self.sub_atributo].attribute
					container = self.showing [atributo]._ActorTable
				else
					total, keyName, first = _detalhes.atributo_damage:RefreshWindow (self, self.showing, true, true)
					total = 1
					atributo = 1
					container = self.showing [atributo]._ActorTable
				end
				--print (total, keyName, first, atributo)
			end
			
			for i = 1, amt do 
				local _thisActor = container [i]
				if (_thisActor) then 
					local amount = _thisActor [keyName]
					if (_type (amount) == "number" and amount > 0) then --1236
						if (keyNameSec) then
							local dps = GetDpsHps (_thisActor, keyNameSec)
							
							local name = _thisActor.nome.." "
							if (_detalhes.remove_realm_from_name and name:find ("-")) then
								name = name:gsub (("%-.*"), "")
							end
							
							_detalhes.fontstring_len:SetText (name)
							local stringlen = _detalhes.fontstring_len:GetStringWidth()
							
							while (stringlen < default_len) do 
								name = name .. "."
								_detalhes.fontstring_len:SetText (name)
								stringlen = _detalhes.fontstring_len:GetStringWidth()
							end

							report_lines [#report_lines+1] = i..". ".. name .." ".. _cstr ("%.2f", amount/total*100) .. "% (" .. _detalhes:comma_value (_math_floor (dps)) .. ", " .. _detalhes:ToK ( _math_floor (amount) ) .. ")"
						else
							report_lines [#report_lines+1] = i..". ".. _thisActor.nome.."   ".. _detalhes:comma_value ( _math_floor (amount) ).." (".._cstr ("%.1f", amount/total*100).."%)"
						end
					elseif (_type (amount) == "string") then
						report_lines [#report_lines+1] = i..". ".. _thisActor.nome.."   ".. amount
					else
						break
					end
				else
					break
				end
			end
	
		else
			for i = 1, amt do
				local ROW = self.barras [i]
				if (ROW) then
					if (not ROW.hidden or ROW.fading_out) then --> a barra esta visivel na tela
						report_lines [#report_lines+1] = ROW.texto_esquerdo:GetText().."   ".. ROW.texto_direita:GetText()
					else
						break
					end
				else
					break --> chegou a final, parar de pegar as linhas
				end
			end
		end
		
	else --> � reverso
		report_lines[1] = report_lines[1].." (" .. Loc ["STRING_REPORTFRAME_REVERTED"] .. ")"
		
		if (not is_current) then 
			--> assumindo que self � sempre uma inst�ncia aqui.
			local total, keyName, first
			local atributo = self.atributo
			
			local container = self.showing [atributo]._ActorTable
			local quantidade = 0
			
			if (atributo == 1) then --> damage
				if (self.sub_atributo == 5) then --> frags
					local frags = self.showing.frags
					local reportarFrags = {}
					for name, amount in pairs (frags) do 
						--> string para imprimir direto sem calculos
						reportarFrags [#reportarFrags+1] = {frag = tostring (amount), nome = name} 
					end
					container = reportarFrags
					keyName = "frag"
				else
					if (self.sub_atributo == 1) then
						keyNameSec = "dps"
					end
					total, keyName, first = _detalhes.atributo_damage:RefreshWindow (self, self.showing, true, true)
				end
			elseif (atributo == 2) then --> heal
				total, keyName, first = _detalhes.atributo_heal:RefreshWindow (self, self.showing, true, true)
				if (self.sub_atributo == 1) then
					keyNameSec = "hps"
				end
			elseif (atributo == 3) then --> energy
				total, keyName, first = _detalhes.atributo_energy:RefreshWindow (self, self.showing, true, true)
			elseif (atributo == 4) then --> misc
				if (self.sub_atributo == 5) then --> mortes
					local mortes = self.showing.last_events_tables
					local reportarMortes = {}
					for index, morte in ipairs (mortes) do 
						reportarMortes [#reportarMortes+1] = {dead = morte [6], nome = morte [3]:gsub (("%-.*"), "")}
					end
					container = reportarMortes
					keyName = "dead"
				else
					total, keyName, first = _detalhes.atributo_misc:RefreshWindow (self, self.showing, true, true)
				end
			elseif (atributo == 5) then --> custom
				total, keyName, first = _detalhes.atributo_custom:RefreshWindow (self, self.showing, true, {key = "custom"})
				total = self.showing.totals [self.customName]
				atributo = _detalhes.custom [self.sub_atributo].attribute
			end

			for i = #container, 1, -1 do 
				
				local _thisActor = container [i]
				local amount = _thisActor [keyName]
				
				if (_type (amount) == "number") then
					if (amount > 0) then 
						if (keyNameSec) then
							local dps = GetDpsHps (_thisActor, keyNameSec)
							
							local name = _thisActor.nome.." "
							
							_detalhes.fontstring_len:SetText (name)
							local stringlen = _detalhes.fontstring_len:GetStringWidth()
							
							while (stringlen < default_len) do 
								name = name .. "."
								_detalhes.fontstring_len:SetText (name)
								stringlen = _detalhes.fontstring_len:GetStringWidth()
							end

							report_lines [#report_lines+1] = i..". ".. name .." ".. _cstr ("%.2f", amount/total*100) .. "% (" .. _detalhes:comma_value (_math_floor (dps)) .. ", " .. _detalhes:ToK ( _math_floor (amount) ) .. ")"
						else
							report_lines [#report_lines+1] = i..".".. _thisActor.nome.."   ".. _detalhes:comma_value ( _math_floor (amount) ).." (".._cstr ("%.1f", amount/total*100).."%)"
						end
						quantidade = quantidade + 1
						if (quantidade == amt) then
							break
						end
					end
				elseif (_type (amount) == "string") then
					report_lines [#report_lines+1] = i..".".. _thisActor.nome.."   ".. amount
				else
					break
				end
			end

		else
			local nova_tabela = {}
			
			for i = 1, amt do
				local ROW = self.barras [i]
				if (ROW) then
					if (not ROW.hidden or ROW.fading_out) then --> a barra esta visivel na tela
						nova_tabela [#nova_tabela+1] = ROW.texto_esquerdo:GetText().."   ".. ROW.texto_direita:GetText()
					else
						break
					end
				else
					break
				end
			end
			
			for i = #nova_tabela, 1, -1 do
				report_lines [#report_lines+1] = nova_tabela[i]
			end
		end

	end
	
	return self:envia_relatorio (report_lines)
	
end

function _detalhes:envia_relatorio (linhas, custom)

	local segmento = self.segmento
	local luta = nil

	if (not custom) then
		if (segmento == -1) then --overall
			luta = Loc ["STRING_REPORT_LAST"] .. " " .. #_detalhes.tabela_historico.tabelas .. " " .. Loc ["STRING_REPORT_FIGHTS"]
			
		elseif (segmento == 0) then --current
		
			if (_detalhes.tabela_vigente.is_boss) then
				local encounterName = _detalhes.tabela_vigente.is_boss.name
				if (encounterName) then
					luta = encounterName
				end
				
			elseif (_detalhes.tabela_vigente.is_pvp) then
				local battleground_name = _detalhes.tabela_vigente.is_pvp.name
				if (battleground_name) then
					luta = battleground_name
				end
			end
			
			if (not luta) then
				if (_detalhes.tabela_vigente.enemy) then
					luta = _detalhes.tabela_vigente.enemy
				end
			end
			
			if (not luta) then
				luta = _detalhes.segmentos.current
			end
		else
			if (segmento == 1) then
			
				if (_detalhes.tabela_historico.tabelas[1].is_boss) then
					local encounterName = _detalhes.tabela_historico.tabelas[1].is_boss.name
					if (encounterName) then
						luta = encounterName .. " (" .. Loc ["STRING_REPORT_LASTFIGHT"]  .. ")"
					end
					
				elseif (_detalhes.tabela_historico.tabelas[1].is_pvp) then
					local battleground_name = _detalhes.tabela_historico.tabelas[1].is_pvp.name
					if (battleground_name) then
						luta = battleground_name .. " (" .. Loc ["STRING_REPORT_LASTFIGHT"]  .. ")"
					end
				end
				
				if (not luta) then
					if (_detalhes.tabela_historico.tabelas[1].enemy) then
						luta = _detalhes.tabela_historico.tabelas[1].enemy .. " (" .. Loc ["STRING_REPORT_LASTFIGHT"]  .. ")"
					end
				end
			
				if (not luta) then
					luta = Loc ["STRING_REPORT_LASTFIGHT"]
				end
				
			else
			
				if (_detalhes.tabela_historico.tabelas[segmento].is_boss) then
					local encounterName = _detalhes.tabela_historico.tabelas[segmento].is_boss.name
					if (encounterName) then
						luta = encounterName .. " (" .. segmento .. " " .. Loc ["STRING_REPORT_PREVIOUSFIGHTS"] .. ")"
					end
					
				elseif (_detalhes.tabela_historico.tabelas[segmento].is_pvp) then
					local battleground_name = _detalhes.tabela_historico.tabelas[segmento].is_pvp.name
					if (battleground_name) then
						luta = battleground_name .. " (" .. Loc ["STRING_REPORT_LASTFIGHT"]  .. ")"
					end
				end
				
				if (not luta) then
					if (_detalhes.tabela_historico.tabelas[segmento].enemy) then
						luta = _detalhes.tabela_historico.tabelas[segmento].enemy .. " (" .. segmento .. " " .. Loc ["STRING_REPORT_PREVIOUSFIGHTS"] .. ")"
					end
				end
			
				if (not luta) then
					luta = " (" .. segmento .. " " .. Loc ["STRING_REPORT_PREVIOUSFIGHTS"] .. ")"
				end
			end
		end

		linhas[1] = linhas[1] .. " " .. Loc ["STRING_REPORT"] .. " " .. luta

	end
	
	if (_detalhes.time_type == 2) then
		linhas[1] = linhas[1] .. " (Ef)"
	else
		linhas[1] = linhas[1] .. " (Ac)"
	end
	
	local editbox = _detalhes.janela_report.editbox
	if (editbox.focus) then --> n�o precionou enter antes de clicar no okey
		local texto = _detalhes:trim (editbox:GetText())
		if (_string_len (texto) > 0) then
			_detalhes.report_to_who = texto
			editbox:AddHistoryLine (texto)
			editbox:SetText (texto)
		else
			_detalhes.report_to_who = ""
			editbox:SetText ("")
		end 
		editbox.perdeu_foco = true --> isso aqui pra quando estiver editando e clicar em outra caixa
		editbox:ClearFocus()
	end

	if (_detalhes.report_where == "COPY") then
		return _detalhes:SendReportTextWindow (linhas)
	end
	
	local to_who = _detalhes.report_where
	
	local channel = to_who:find ("CHANNEL")
	local is_btag = to_who:find ("REALID")
	
	if (channel) then
		
		channel = to_who:gsub ((".*|"), "")

		for i = 1, #linhas do 
			_SendChatMessage (linhas[i], "CHANNEL", nil, _GetChannelName (channel))
		end
		
		return
		
	elseif (is_btag) then
	
		local id = to_who:gsub ((".*|"), "")
		local presenceID = tonumber (id)
		
		for i = 1, #linhas do 
			BNSendWhisper (presenceID, linhas[i])
		end
		
		return

	elseif (to_who == "WHISPER") then --> whisper
	
		local alvo = _detalhes.report_to_who
		
		if (not alvo or alvo == "") then
			print (Loc ["STRING_REPORT_INVALIDTARGET"])
			return
		end
		
		for i = 1, #linhas do 
			_SendChatMessage (linhas[i], to_who, nil, alvo)
		end
		return
		
	elseif (to_who == "WHISPER2") then --> whisper target
		to_who = "WHISPER"
		
		local alvo
		if (_UnitExists ("target")) then
			if (_UnitIsPlayer ("target")) then
				alvo = _UnitName ("target")
			else
				print (Loc ["STRING_REPORT_INVALIDTARGET"])
				return
			end
		else
			print (Loc ["STRING_REPORT_INVALIDTARGET"])
			return
		end
		
		for i = 1, #linhas do 
			_SendChatMessage (linhas[i], to_who, nil, alvo)
		end

		return
	end
	
	if (to_who == "RAID") then
		--LE_PARTY_CATEGORY_HOME - default
		--LE_PARTY_CATEGORY_INSTANCE - player's automatic group, raid finder?.
		if (GetNumGroupMembers (LE_PARTY_CATEGORY_INSTANCE) > 0) then
			to_who = "INSTANCE_CHAT"
		end
	end
	
	for i = 1, #linhas do 
		_SendChatMessage (linhas[i], to_who)
	end
	
end
