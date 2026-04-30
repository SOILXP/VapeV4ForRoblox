--[[
	Prediction Library
	Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]
local module = {}

local EPS = 1e-7
local ROOT_EPS = 1e-5
local MAX_BISECT = 80

local abs = math.abs
local sqrt = math.sqrt
local max = math.max
local min = math.min
local huge = math.huge

local function nearZero(x, eps)
	eps = eps or EPS
	return x > -eps and x < eps
end

local function signOf(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	end
	return 0
end

local function copyTrim(coeffs)
	local out = table.create(#coeffs)
	local first = 1

	while first < #coeffs and nearZero(coeffs[first]) do
		first += 1
	end

	for i = first, #coeffs do
		out[#out + 1] = coeffs[i]
	end

	if #out == 0 then
		out[1] = 0
	end

	return out
end

local function polyEval(coeffs, x)
	local y = coeffs[1]
	for i = 2, #coeffs do
		y = (y * x) + coeffs[i]
	end
	return y
end

local function derivative(coeffs)
	local degree = #coeffs - 1
	local out = table.create(degree)

	for i = 1, degree do
		out[i] = coeffs[i] * (degree - i + 1)
	end

	return copyTrim(out)
end

local function rootBound(coeffs)
	coeffs = copyTrim(coeffs)
	local lead = abs(coeffs[1])
	if lead < EPS then
		return 1
	end

	local m = 0
	for i = 2, #coeffs do
		m = max(m, abs(coeffs[i]) / lead)
	end

	local bound = 1 + m
	if bound < 1 then
		bound = 1
	end

	return bound
end

local function insertRoot(list, root)
	if root ~= root or root == huge or root == -huge then
		return
	end

	for i = 1, #list do
		if abs(list[i] - root) <= ROOT_EPS * max(1, abs(root)) then
			list[i] = (list[i] + root) * 0.5
			return
		end
	end

	list[#list + 1] = root
end

local function sortUnique(list)
	table.sort(list)

	local out = table.create(#list)
	for i = 1, #list do
		insertRoot(out, list[i])
	end

	table.sort(out)
	return out
end

local function solveLinear(a, b)
	if nearZero(a) then
		return {}
	end
	return { -b / a }
end

local function solveRealPolynomial(coeffs)
	coeffs = copyTrim(coeffs)
	local degree = #coeffs - 1

	if degree <= 0 then
		return {}
	end

	if degree == 1 then
		return solveLinear(coeffs[1], coeffs[2])
	end

	local roots = {}
	local crit = solveRealPolynomial(derivative(coeffs))
	crit = sortUnique(crit)

	local bound = rootBound(coeffs)
	local points = table.create(#crit + 2)
	points[1] = -bound
	for i = 1, #crit do
		if crit[i] > -bound and crit[i] < bound then
			points[#points + 1] = crit[i]
		end
	end
	points[#points + 1] = bound
	table.sort(points)

	local scale = 0
	for i = 1, #coeffs do
		scale += abs(coeffs[i])
	end
	local yTol = max(EPS, scale * 1e-7)

	for i = 1, #crit do
		local x = crit[i]
		if x >= -bound and x <= bound and abs(polyEval(coeffs, x)) <= yTol * max(1, abs(x) ^ degree) then
			insertRoot(roots, x)
		end
	end

	for i = 1, #points - 1 do
		local left = points[i]
		local right = points[i + 1]

		if right > left then
			local fl = polyEval(coeffs, left)
			local fr = polyEval(coeffs, right)

			if abs(fl) <= yTol then
				insertRoot(roots, left)
			elseif abs(fr) <= yTol then
				insertRoot(roots, right)
			elseif signOf(fl) ~= signOf(fr) then
				local a = left
				local b = right
				local fa = fl
				local fb = fr
				local mid = (a + b) * 0.5

				for _ = 1, MAX_BISECT do
					mid = (a + b) * 0.5
					local fm = polyEval(coeffs, mid)

					if abs(fm) <= yTol or abs(b - a) <= ROOT_EPS * max(1, abs(mid)) then
						break
					end

					if signOf(fa) == signOf(fm) then
						a = mid
						fa = fm
					else
						b = mid
						fb = fm
					end
				end

				insertRoot(roots, mid)
			end
		end
	end

	return sortUnique(roots)
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local roots = solveRealPolynomial({ c0 or 0, c1 or 0, c2 or 0, c3 or 0, c4 or 0 })
	return roots
end

local function smallestPositiveRoot(roots)
	local best = huge

	for i = 1, #roots do
		local t = roots[i]
		if t and t > ROOT_EPS and t < best then
			best = t
		end
	end

	if best ~= huge then
		return best
	end
end

local function solveInterceptTime(disp, targetVelocity, projectileSpeed, projectileGravity, targetGravity)
	local h = disp.X
	local j = disp.Y
	local k = disp.Z

	local p = targetVelocity.X
	local q = targetVelocity.Y
	local r = targetVelocity.Z

	local a = 0.5 * ((projectileGravity or 0) - (targetGravity or 0))

	local c0 = a * a
	local c1 = 2 * q * a
	local c2 = (q * q) + (2 * j * a) + (p * p) + (r * r) - (projectileSpeed * projectileSpeed)
	local c3 = 2 * ((j * q) + (h * p) + (k * r))
	local c4 = (h * h) + (j * j) + (k * k)

	return smallestPositiveRoot(module.solveQuartic(c0, c1, c2, c3, c4))
end

local function getAimVelocity(origin, projectileSpeed, projectileGravity, targetPos, targetVelocity, targetGravity, t)
	local disp = targetPos - origin
	local accelComp = 0.5 * ((projectileGravity or 0) - (targetGravity or 0)) * t

	local velocity = Vector3.new(
		(disp.X / t) + targetVelocity.X,
		(disp.Y / t) + targetVelocity.Y + accelComp,
		(disp.Z / t) + targetVelocity.Z
	)

	local mag = velocity.Magnitude
	if mag > EPS then
		velocity = velocity.Unit * projectileSpeed
	end

	return velocity
end

local function estimateLanding(origin, projectileSpeed, targetPos, targetVelocity, targetGravity, playerHeight, rayParams)
	if not rayParams or not targetGravity or targetGravity <= 0 then
		return nil
	end

	local height = playerHeight or 0
	local rawGuess = (targetPos - origin).Magnitude / max(projectileSpeed, 1)
	local maxTime = math.clamp((rawGuess * 1.75) + 0.35, 0.25, 4)
	local steps = math.clamp(math.ceil(maxTime * 40), 12, 120)

	local downOffset = Vector3.new(0, height, 0)
	local lastBase = targetPos - downOffset

	for i = 1, steps do
		local t = (maxTime * i) / steps
		local nextPos = targetPos + (targetVelocity * t) + Vector3.new(0, -0.5 * targetGravity * t * t, 0)
		local nextBase = nextPos - downOffset
		local dir = nextBase - lastBase

		if dir.Magnitude > EPS then
			local hit = workspace:Raycast(lastBase, dir, rayParams)
			if hit then
				local horizontal = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
				local landedPos = hit.Position + downOffset
				return landedPos, horizontal, t
			end
		end

		lastBase = nextBase
	end

	return nil
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params)
	if not origin or not targetPos or not targetVelocity then
		return nil
	end

	projectileSpeed = projectileSpeed or 0
	gravity = gravity or 0

	if projectileSpeed <= EPS then
		return nil
	end

	local solveTargetPos = targetPos
	local solveTargetVelocity = targetVelocity
	local solveTargetGravity = 0

	if playerGravity and playerGravity > 0 and abs(targetVelocity.Y) > 0.01 then
		solveTargetGravity = playerGravity

		local landedPos, landedVelocity, landedTime = estimateLanding(origin, projectileSpeed, targetPos, targetVelocity, playerGravity, playerHeight, params)
		if landedPos and landedVelocity and landedTime then
			solveTargetPos = landedPos - (landedVelocity * landedTime)
			solveTargetVelocity = landedVelocity
			solveTargetGravity = 0
		end
	end

	local t = solveInterceptTime(solveTargetPos - origin, solveTargetVelocity, projectileSpeed, gravity, solveTargetGravity)
	if not t then
		return nil
	end

	local velocity = getAimVelocity(origin, projectileSpeed, gravity, solveTargetPos, solveTargetVelocity, solveTargetGravity, t)
	return origin + velocity
end

return module
