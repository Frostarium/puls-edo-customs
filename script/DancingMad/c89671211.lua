--Goddess of the Warring Triad
local s,id=GetID()
local COUNTER_ENTICEMENT=0x1634
local COUNTER_DOOM=0x1637
local CARD_STATUE_OF_THE_GODS=89671213
local CARD_CLOUDY_HEAVEN=89671212
--number of Doom Counters placed on the target
local DOOM_COUNT=2
s.listed_names={CARD_STATUE_OF_THE_GODS,CARD_CLOUDY_HEAVEN}
function s.initial_effect(c)
	--Link Summon procedure: 2 Level 3 LIGHT Fairy monsters
	Link.AddProcedure(c,s.matfilter,2,2)
	--Place an Enticement Counter on 1 monster (or, while you control a face-up "Cloudy Heaven", you can place 2 Doom Counters on it instead)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	--Monsters with an Enticement Counter are always in Attack Position
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.enttg)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_SET_POSITION)
	e4:SetValue(POS_FACEUP_ATTACK)
	c:RegisterEffect(e4)
	--...and must attack, if able
	local e5=e2:Clone()
	e5:SetCode(EFFECT_MUST_ATTACK)
	c:RegisterEffect(e5)
	--...but cannot attack if their controller has no other monster without a counter
	local e8=e2:Clone()
	e8:SetCode(EFFECT_CANNOT_ATTACK)
	e8:SetTarget(s.noatktg)
	c:RegisterEffect(e8)
	--...and when they attack, they attack another monster their controller controls that has no counter
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_BATTLE_CONFIRM)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.atkcon)
	e6:SetOperation(s.rdop)
	c:RegisterEffect(e6)
	--During the End Phase, take control of all monsters with Enticement Counters and remove the counters
	local e7=Effect.CreateEffect(c)
	e7:SetCategory(CATEGORY_CONTROL)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e7:SetCode(EVENT_PHASE+PHASE_END)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1)
	e7:SetCondition(s.ctrcon)
	e7:SetTarget(s.ctrtg)
	e7:SetOperation(s.ctrop)
	c:RegisterEffect(e7)
	--Monsters summoned using an enticed monster as material or Tribute become enticed (backup check)
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCondition(s.sumcon)
	e9:SetOperation(s.sumop)
	c:RegisterEffect(e9)
	local e10=e9:Clone()
	e10:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e10)
end
s.counter_place_list={COUNTER_ENTICEMENT}
function s.matfilter(c,lc,sumtype,tp)
	return c:IsLevel(3) and c:IsAttribute(ATTRIBUTE_LIGHT,lc,sumtype,tp) and c:IsRace(RACE_FAIRY,lc,sumtype,tp)
end
function s.enttg(e,c)
	return c:IsFaceup() and c:GetCounter(COUNTER_ENTICEMENT)>0
end
function s.ctfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(COUNTER_ENTICEMENT,1)
end
--Doom Counters (with a face-up "Cloudy Heaven" on your field): the counters themselves, and what they do, are in its script
function s.dmfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(COUNTER_DOOM,DOOM_COUNT)
end
function s.cloudyfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_CLOUDY_HEAVEN)
end
--e:GetLabel(): 1 = Enticement Counter, 2 = Doom Counters
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp)
			and ((e:GetLabel()==2 and s.dmfilter(chkc)) or (e:GetLabel()~=2 and s.ctfilter(chkc)))
	end
	local b1=Duel.IsExistingTarget(s.ctfilter,tp,0,LOCATION_MZONE,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.cloudyfilter,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingTarget(s.dmfilter,tp,0,LOCATION_MZONE,1,nil)
	if chk==0 then return b1 or b2 end
	local op=1
	if b1 and b2 then
		op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,0)},
			{b2,aux.Stringid(id,1)})
	elseif b2 then
		op=2
	end
	e:SetLabel(op)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	if op==2 then
		local g=Duel.SelectTarget(tp,s.dmfilter,tp,0,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,COUNTER_DOOM,DOOM_COUNT)
	else
		local g=Duel.SelectTarget(tp,s.ctfilter,tp,0,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,COUNTER_ENTICEMENT,1)
	end
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--"Statue of the Gods": if the coin toss for this activation was tails, apply this to all monsters your opponent controls instead
	local tails=c:GetFlagEffectLabel(CARD_STATUE_OF_THE_GODS)==Duel.GetCurrentChain()
	if e:GetLabel()==2 then
		--Doom: 2 counters on the target (1 on every monster your opponent controls on tails)
		local cloudy=_G["c"..CARD_CLOUDY_HEAVEN]
		if tails then
			local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsCanAddCounter(COUNTER_DOOM,1) end,tp,0,LOCATION_MZONE,nil)
			for tc in g:Iter() do
				cloudy.place(tc,tp,1,true)
			end
		else
			local tc=Duel.GetFirstTarget()
			if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
				cloudy.place(tc,tp,DOOM_COUNT,false)
			end
		end
		return
	end
	if tails then
		local g=Duel.GetMatchingGroup(s.ctfilter,tp,0,LOCATION_MZONE,nil)
		for tc in g:Iter() do
			if tc:AddCounter(COUNTER_ENTICEMENT,1) then
				s.regmaterial(c,tc)
			end
		end
		return
	end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:AddCounter(COUNTER_ENTICEMENT,1) then
		s.regmaterial(e:GetHandler(),tc)
	end
end
--if an enticed monster is used as material for a Fusion/Synchro/Xyz/Link Summon, or tributed for a Normal Summon, the summoned monster becomes enticed
local MATERIAL_REASONS=REASON_FUSION|REASON_SYNCHRO|REASON_XYZ|REASON_LINK|REASON_SUMMON
function s.regmaterial(c,tc)
	if tc:HasFlagEffect(id) then return end
	tc:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EVENT_BE_PRE_MATERIAL)
	e1:SetCondition(s.matcon)
	e1:SetOperation(s.matop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
	--backup: remember that it had a counter right before it leaves the field (the counter is lost once it does)
	local e2=e1:Clone()
	e2:SetCode(EVENT_LEAVE_FIELD_P)
	e2:SetCondition(s.leavecon)
	e2:SetOperation(s.leaveop)
	tc:RegisterEffect(e2,true)
end
function s.leavecon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetCounter(COUNTER_ENTICEMENT)>0
end
function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id+1,RESET_PHASE|PHASE_END,0,1)
end
--backup: when a monster is summoned, check whether any of its materials/tributes had a counter
function s.sumfilter(c)
	return c:IsFaceup() and c:GetCounter(COUNTER_ENTICEMENT)==0 and not c:IsSummonType(SUMMON_TYPE_RITUAL)
		and c:GetMaterial():IsExists(Card.HasFlagEffect,1,nil,id+1)
end
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.sumfilter,1,nil)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	for tc in eg:Filter(s.sumfilter,nil):Iter() do
		if tc:AddCounter(COUNTER_ENTICEMENT,1) then
			s.regmaterial(e:GetHandler(),tc)
		end
	end
end
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (r&MATERIAL_REASONS)~=0 and c:GetReasonCard()~=nil and c:GetCounter(COUNTER_ENTICEMENT)>0
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	local e1=Effect.CreateEffect(e:GetOwner())
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode((r&REASON_SUMMON)~=0 and EVENT_SUMMON_SUCCESS or EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.entsumop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
end
function s.entsumop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local owner=e:GetOwner()
	e:Reset()
	if c:IsFaceup() and c:GetCounter(COUNTER_ENTICEMENT)==0 and c:AddCounter(COUNTER_ENTICEMENT,1) then
		s.regmaterial(owner,c)
	end
end
--the engine only lets a monster attack the other side, so the battle is redirected (see Ancient Lamp)
--monsters the attacker could be redirected into: its controller's other monsters without a counter
function s.victimfilter(c,a)
	return c~=a and c:GetCounter(COUNTER_ENTICEMENT)==0
end
function s.noatktg(e,c)
	return s.enttg(e,c) and not Duel.IsExistingMatchingCard(s.victimfilter,c:GetControler(),LOCATION_MZONE,0,1,nil,c)
end
function s.atkcon(e)
	local a=Duel.GetAttacker()
	return a and a:GetCounter(COUNTER_ENTICEMENT)>0
		and Duel.IsExistingMatchingCard(s.victimfilter,a:GetControler(),LOCATION_MZONE,0,1,nil,a)
end
function s.rdop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	if not a:CanAttack() or a:IsImmuneToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.victimfilter,a:GetControler(),LOCATION_MZONE,0,nil,a)
	local tc=g:GetFirst()
	if #g>1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACKTARGET)
		tc=g:Select(tp,1,1,nil):GetFirst()
	end
	Duel.HintSelection(tc)
	Duel.CalculateDamage(a,tc)
end
function s.ctrfilter(c)
	return c:GetCounter(COUNTER_ENTICEMENT)>0
end
function s.ctrcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.ctrfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.ctrtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(s.ctrfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g:Filter(Card.IsControler,nil,1-tp),#g,0,0)
end
function s.ctrop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ctrfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then return end
	local og=g:Filter(function(c) return c:IsControler(1-tp) and c:IsControlerCanBeChanged() end,nil)
	--take control of as many as there are free zones this card points to (you choose which, if there are more than zones)
	local zone=e:GetHandler():GetLinkedZone(tp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL,zone)
	if zone~=0 and ft>0 and #og>0 then
		if #og>ft then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
			og=og:Select(tp,ft,ft,nil)
		end
		for tc in og:Iter() do
			Duel.GetControl(tc,tp,0,0,zone)
		end
	end
	for tc in g:Iter() do
		tc:RemoveCounter(tp,COUNTER_ENTICEMENT,tc:GetCounter(COUNTER_ENTICEMENT),REASON_EFFECT)
	end
end
