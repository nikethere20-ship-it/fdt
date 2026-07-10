CREATE OR REPLACE FUNCTION public.generate_key(
  p_token TEXT,
  p_key_name TEXT,
  p_package_id UUID,
  p_expiry_days INT,
  p_hwid_lock BOOLEAN,
  p_hwid_reset_allowed BOOLEAN,
  p_custom_key TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user public.users;
  v_key_string TEXT;
  v_key_id UUID;
BEGIN
  SELECT u.* INTO v_user FROM public.users u
  JOIN public.sessions s ON s.user_id = u.id
  WHERE s.token = p_token AND s.expires_at > NOW();
  IF v_user.id IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid session');
  END IF;
  IF p_expiry_days > 2012 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Max expiry is 2012 days');
  END IF;
  IF v_user.role NOT IN ('owner', 'admin') AND NOT v_user.credits_infinite THEN
    IF v_user.credits <= 0 THEN
      RETURN json_build_object('success', FALSE, 'error', 'Insufficient credits');
    END IF;
    UPDATE public.users SET credits = credits - 1 WHERE id = v_user.id;
    INSERT INTO public.credit_logs (reseller_id, action, amount, description)
    VALUES (v_user.id, 'key_generated', -1, 'Key generation: ' || COALESCE(p_key_name, 'unnamed'));
  END IF;
  IF p_custom_key IS NOT NULL AND p_custom_key != '' THEN
    PERFORM 1 FROM public.keys WHERE key_string = p_custom_key;
    IF FOUND THEN
      RETURN json_build_object('success', FALSE, 'error', 'Key already exists');
    END IF;
    v_key_string := p_custom_key;
  ELSE
    v_key_string := upper(substr(encode(gen_random_bytes(16), 'hex'), 1, 32));
  END IF;
  INSERT INTO public.keys (key_string, key_name, package_id, created_by_reseller, expiry_days, hwid_reset_allowed, status)
  VALUES (v_key_string, p_key_name, p_package_id, v_user.id, p_expiry_days, p_hwid_reset_allowed, 'active')
  RETURNING id INTO v_key_id;
  RETURN json_build_object('success', TRUE, 'key_id', v_key_id, 'key_string', v_key_string);
END;
$$;
